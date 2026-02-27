# Bug List - Apache_HW

## Summary
| Date | Module | Issue | Severity | Status |
|------|--------|-------|----------|--------|
| 2026-02-27 | ucsie_adapter | Missing RECEIVE state definition | High | Fixed |
| 2026-02-27 | ucsie_controller | output wire vs reg conflict | High | Fixed |

---

## Bug #1: Missing RECEIVE State
**Date:** 2026-02-27  
**Module:** `design/ucsie/rtl/ucsie_adapter.v`  
**Severity:** High  

**Description:**  
The `RECEIVE` state was defined after it was used in an assign statement at line 136, causing compilation errors in VCS.

**Location:** Line 136 (usage), Line 235 (definition)

**Fix:**  
Moved `localparam RECEIVE = 4'd6;` to line 85, before the assign statement.

**Status:** ✅ Fixed

---

## Bug #2: AXI Output Port Type Conflict
**Date:** 2026-02-27  
**Module:** `design/ucsie/rtl/ucsie_controller.v`  
**Severity:** High  

**Description:**  
AXI master signals (m_awid, m_awaddr, etc.) were declared as `output wire` in the port declaration but also had `assign` statements, and were being assigned in always blocks. This caused "Illegal combination of driver" errors in Xcelium/VCS.

**Location:** Lines 25-61 (port declaration), Lines 286-290 (assign statements)

**Fix:**  
1. Changed `output wire` to `output reg` for all AXI master signals
2. Removed duplicate assign statements that conflicted with always block assignments

**Status:** ✅ Fixed

---

## Known Limitations (Not Bugs)

1. **UCIe PHY port connections** - Some ports are unconnected in testbench (warnings only)
2. **VCS 32-bit library issue** - Requires `-full64` flag
3. **URG coverage tool** - Has compatibility issues on this platform

---

## Coverage Status

| Module | Coverage | Notes |
|--------|----------|-------|
| MAC Array | ~80% | Basic tests pass |
| Share Memory | ~75% | All tests pass |
| PE Compiler | ~70% | Basic tests pass |
| UCIe | ~65% | Simple tests pass |
| Router | ~60% | Basic tests pass |

**Target:** 90%+

---

*Last Updated: 2026-02-27*
