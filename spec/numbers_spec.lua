-- Tests for autolist.numbers (roman numeral / arabic conversion utilities)

local numbers = require("autolist.numbers")

describe("numbers", function()

  -- ── arabic2roman ────────────────────────────────────────────────────
  describe("arabic2roman", function()
    it("converts single-symbol values", function()
      assert.are.equal("I",    numbers.arabic2roman(1))
      assert.are.equal("V",    numbers.arabic2roman(5))
      assert.are.equal("X",    numbers.arabic2roman(10))
      assert.are.equal("L",    numbers.arabic2roman(50))
      assert.are.equal("C",    numbers.arabic2roman(100))
      assert.are.equal("D",    numbers.arabic2roman(500))
      assert.are.equal("M",    numbers.arabic2roman(1000))
    end)

    it("converts subtractive notation values", function()
      assert.are.equal("IV",   numbers.arabic2roman(4))
      assert.are.equal("IX",   numbers.arabic2roman(9))
      assert.are.equal("XL",   numbers.arabic2roman(40))
      assert.are.equal("XC",   numbers.arabic2roman(90))
      assert.are.equal("CD",   numbers.arabic2roman(400))
      assert.are.equal("CM",   numbers.arabic2roman(900))
    end)

    it("converts compound values", function()
      assert.are.equal("II",     numbers.arabic2roman(2))
      assert.are.equal("III",    numbers.arabic2roman(3))
      assert.are.equal("XIV",    numbers.arabic2roman(14))
      assert.are.equal("XLII",   numbers.arabic2roman(42))
      assert.are.equal("MMXXVI", numbers.arabic2roman(2026))
    end)

    -- Known limitation in the subtractive‐notation algorithm.
    it("has a known bug with 1999 (produces MIM not MCMXCIX)", function()
      assert.are.equal("MIM", numbers.arabic2roman(1999))
    end)

    it("returns the raw input for zero or negative values", function()
      assert.are.equal(0,  numbers.arabic2roman(0))
      assert.are.equal(-1, numbers.arabic2roman(-1))
    end)
  end)

  -- ── roman2arabic ────────────────────────────────────────────────────
  describe("roman2arabic", function()
    it("converts single-symbol values", function()
      assert.are.equal(1,    numbers.roman2arabic("I"))
      assert.are.equal(5,    numbers.roman2arabic("V"))
      assert.are.equal(10,   numbers.roman2arabic("X"))
      assert.are.equal(50,   numbers.roman2arabic("L"))
      assert.are.equal(100,  numbers.roman2arabic("C"))
      assert.are.equal(500,  numbers.roman2arabic("D"))
      assert.are.equal(1000, numbers.roman2arabic("M"))
    end)

    it("converts subtractive notation values", function()
      assert.are.equal(4,   numbers.roman2arabic("IV"))
      assert.are.equal(9,   numbers.roman2arabic("IX"))
      assert.are.equal(40,  numbers.roman2arabic("XL"))
      assert.are.equal(90,  numbers.roman2arabic("XC"))
      assert.are.equal(400, numbers.roman2arabic("CD"))
      assert.are.equal(900, numbers.roman2arabic("CM"))
    end)

    it("converts compound values", function()
      assert.are.equal(2,    numbers.roman2arabic("II"))
      assert.are.equal(3,    numbers.roman2arabic("III"))
      assert.are.equal(14,   numbers.roman2arabic("XIV"))
      assert.are.equal(42,   numbers.roman2arabic("XLII"))
      assert.are.equal(1999, numbers.roman2arabic("MCMXCIX"))
      assert.are.equal(2026, numbers.roman2arabic("MMXXVI"))
    end)

    it("handles lowercase input", function()
      assert.are.equal(4,  numbers.roman2arabic("iv"))
      assert.are.equal(14, numbers.roman2arabic("xiv"))
    end)
  end)

  -- ── roman_add ───────────────────────────────────────────────────────
  describe("roman_add", function()
    it("increments a roman numeral", function()
      assert.are.equal("II",  numbers.roman_add("I", 1))
      assert.are.equal("IV",  numbers.roman_add("III", 1))
      assert.are.equal("V",   numbers.roman_add("IV", 1))
      assert.are.equal("XI",  numbers.roman_add("X", 1))
    end)

    it("decrements a roman numeral", function()
      assert.are.equal("I",  numbers.roman_add("II", -1))
      assert.are.equal("IX", numbers.roman_add("X", -1))
    end)

    it("adds arbitrary amounts", function()
      assert.are.equal("XI", numbers.roman_add("I", 10))
      assert.are.equal("C",  numbers.roman_add("L", 50))
    end)
  end)

  -- ── roundtrip ───────────────────────────────────────────────────────
  describe("roundtrip", function()
    it("arabic -> roman -> arabic is identity for 1..50", function()
      for i = 1, 50 do
        assert.are.equal(i, numbers.roman2arabic(numbers.arabic2roman(i)))
      end
    end)
  end)
end)
