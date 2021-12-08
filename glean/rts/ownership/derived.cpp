/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <numeric>
#include <folly/container/F14Map.h>

#include "glean/rts/ownership/derived.h"
#include "glean/rts/timer.h"

namespace facebook {
namespace glean {
namespace rts {

void DefineOwnership::derivedFrom(Id id, const std::set<UsetId>& deps) {
  if (deps.size() == 0) {
    LOG(ERROR) << "DefineOwnership::derivedFrom: empty deps";
    return;
  }

  SetU32 set = SetU32::from(deps);

  UsetId usetid;
  if (set.size() == 1) {
    usetid = *deps.begin();
  } else {
    auto uset = std::make_unique<Uset>(set, And, 0);
    size_t size = set.size();
    usetid = ownership_->lookupSet(uset.get());
    if (usetid == INVALID_USET) {
      auto q = uset.get();
      auto p = usets_.add(std::move(uset));
      if (p == q) {
        usets_.promote(p);
        usetid = p->id;
        newSets_.push_back(p);
        VLOG(2) << "new set: " << usetid << ", size = " << size;
      } else {
        usetid = p->id;
        VLOG(2) << "existing set in batch: " << usetid;
      }
    } else {
      VLOG(2) << "existing set in DB: " << usetid;
    }
  }

  if (id >= first_id_) {
    new_ids_.push_back(id);
    new_owners_.push_back(usetid);
  } else {
    ids_.push_back(id);
    owners_.push_back(usetid);
  }
}

std::vector<int64_t> DefineOwnership::sortByOwner(uint64_t facts) {
  // We have a set of facts in the batch with Ids [first_id, first_id+1, ..]
  // We want to group these facts by owner, so that facts with the same
  // owner are adjacent.
  //
  // We're going to rearrange the facts and give them new IDs.
  //
  // 0. we start with
  //       ids =    [ 0, 1, 2, 3, 0 ]
  //       owners = [ C, B, A, B, A ]
  //  Note that we may have recorded multiple owners for some facts.
  //
  // 1. make a vector of owners, indexed by fact ID:
  //          [ X, B, A, B ]
  // for a fact that has multiple owners, we'll make up a temporary
  // new set Id. These are only for sorting purposes, they're not real
  // set Ids - the real ones are created later in
  // computeDerivedOwnership().
  //
  // e.g. we need a new set ID (let's use X) to represent the owner of
  // fact 0, because it has multiple owners assigned (C and A).

  std::vector<UsetId> owners(facts, INVALID_USET);

  auto tmpset = usets_.getNextId();
  for (size_t i = 0; i < new_ids_.size(); i++) {
    auto ix = new_ids_[i] - first_id_;
    if (owners[ix] == INVALID_USET) {
      owners[ix] = new_owners_[i];
    } else {
      // this fact has multiple owners, use a new temporary UsetId.
      owners[ix] = tmpset++;
    }
  }

  // 2. make a vector order = [0..facts-1]
  // this will become the ordering that we return after we sort it.

  std::vector<int64_t> order(facts);
  std::iota(order.begin(), order.end(), first_id_.toWord());

  // 2. sort order by owner = [ 2, 1, 3, 0 ]
  //
  // This is the order in which we will serialize the facts, which
  // essentially renumbers them. Hence the facts will be renumbered
  //    2 -> 0
  //    1 -> 1
  //    3 -> 2
  //    0 -> 3

  sort(order.begin(), order.end(), [&](uint64_t a, uint64_t b) {
    return owners[a - first_id_.toWord()] < owners[b - first_id_.toWord()];
  });

  // 3. produce a mapping from old fact Ids to new fact Ids

  std::vector<Id> idmap(facts);
  for (size_t i = 0; i < facts; i++) {
    idmap[order[i] - first_id_.toWord()] = Id::fromWord(i + first_id_.toWord());
  }

  // 4. substitute fact IDs in new_ids

  for (size_t i = 0; i < new_ids_.size(); i++) {
    new_ids_[i] = idmap[new_ids_[i] - first_id_];
  }

  return order;

  // At this point we must serialize the batch using
  // serializeReorder(order) so that the facts agree with the IDs used
  // in this DefineOwnership.
}

void DefineOwnership::subst(const Substitution& subst) {
  for (auto& id : ids_) {
    id = subst.subst(id);
  }
  for (auto& id : new_ids_) {
    id = subst.subst(id);
  }
}

std::unique_ptr<ComputedOwnership> computeDerivedOwnership(
  Ownership& ownership,
  DerivedFactOwnershipIterator *iter) {
  auto t = makeAutoTimer("computeDerivedOwnership");
  VLOG(1) << "computing derived ownership";

  // Here we are identifying facts that were derived multiple
  // different ways.  e.g. if a fact was derived twice with owners A
  // and B, then its final ownership set will be A || B. That is, the
  // fact will be visibile (derivable) if either A or B are visible.

  std::map<uint64_t,UsetId> factOwners;
  folly::F14FastMap<int64_t,std::set<UsetId>> factOwnerSets;

  while (const auto owners = iter->get()) {
    for (uint32_t i = 0; i < owners->ids.size(); i++) {
      auto id = owners->ids[i].toWord();
      auto owner = owners->owners[i];
      const auto [it, inserted] = factOwners.insert({id, owner});
      if (!inserted) {
        const auto [it2, _] = factOwnerSets.insert({id, {it->second}});
        it2->second.insert(owner);
      }
    }
  }

  // Create all the new sets
  //   we are under the write lock here, so we can create canonical
  //   sets, no need to rebase them later.

  Usets usets(ownership.nextSetId());

  for (auto& pair : factOwnerSets) {
    if (pair.second.size() > 1) {
      SetU32 set = SetU32::from(pair.second);
      auto uset = std::make_unique<Uset>(std::move(set), Or, 0);
      auto usetid = ownership.lookupSet(uset.get());
      if (usetid == INVALID_USET) {
        auto p = usets.add(std::move(uset));
        usets.promote(p);
        usetid = p->id;
        VLOG(1) << "new set: " << usetid;
      } else {
        VLOG(1) << "existing set: " << usetid;
      }
      factOwners[pair.first] = usetid;
    }
  }

  auto sets = usets.toEliasFano();

  // convert factOwners into a vector of intervals
  std::vector<std::pair<Id,UsetId>> intervals;
  intervals.reserve(factOwners.size());
  UsetId current = INVALID_USET;
  for (auto& pair : factOwners) {
    auto usetid = pair.second;
    if (usetid != current) {
      intervals.push_back(std::make_pair(Id::fromWord(pair.first), usetid));
      current = usetid;
    }
  }

  VLOG(1) << "computing derived ownership: " <<
    intervals.size() << " intervals";

  // Now build a ComputedOwnership that we can return
  return std::make_unique<ComputedOwnership>(
      usets.getFirstId(),
      std::move(sets),
      std::move(intervals));

}

}
}
}
