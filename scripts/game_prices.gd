extends RefCounted

const CAT = 1
const MERGE = 2
const UPGRADE = 3
const TIER_1 = CAT * 2 + MERGE
const TIER_2 = TIER_1 * 2 + MERGE
const TIER_3 = TIER_2 + TIER_1 + MERGE
const TIER_4 = TIER_2 * 2 + MERGE