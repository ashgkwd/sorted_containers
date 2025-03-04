# frozen_string_literal: true

RSpec.describe SortedContainers::SortedSet do
  describe "to_a" do
    it "sorts items after being added in an arbitrary order" do
      set = SortedContainers::SortedSet.new
      set.add(5)
      set.add(2)
      set.add(7)
      set.add(1)
      set.add(4)
      expect(set.to_a).to eq([1, 2, 4, 5, 7])
    end
  end

  describe "include?" do
    it "should return true if the value is in the set" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(set.include?(3)).to be true
    end
  end

  describe "bisect_left" do
    it "should return the index where the value should be inserted" do
      array = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(array.bisect_left(3)).to eq(2)
    end

    it "should return the the length of the array if the value is greater than all values" do
      array = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(array.bisect_left(6)).to eq(5)
    end

    it "should return 0 if the value is less than all values" do
      array = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(array.bisect_left(0)).to eq(0)
    end
  end

  describe "bisect_right" do
    it "should return the index where the value should be inserted" do
      array = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(array.bisect_right(3)).to eq(3)
    end

    it "should return the the length of the array if the value is greater than all values" do
      array = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(array.bisect_right(6)).to eq(5)
    end

    it "should return 0 if the value is less than all values" do
      array = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(array.bisect_right(0)).to eq(0)
    end
  end

  describe "delete" do
    it "should remove the value from the set" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      set.delete(3)
      expect(set.to_a).to eq([1, 2, 4, 5])
    end

    it "should return the value if it was removed" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      value = set.delete(3)
      expect(value).to eq(3)
    end

    it "should return nil if the value was not removed" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      value = set.delete(300)
      expect(value).to be_nil
    end
  end

  describe "delete_at" do
    it "should remove item at the given index" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      value = set.delete_at(2)
      expect(value).to eq(3)
      expect(set.to_a).to eq([1, 2, 4, 5])
    end

    it "should return nil if index is out of range" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      value = set.delete_at(200)
      expect(value).to be_nil
      expect(set.to_a).to eq([1, 2, 3, 4, 5])
    end

    it "should handle negative indices" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      value = set.delete_at(-3)
      expect(value).to eq(3)
      expect(set.to_a).to eq([1, 2, 4, 5])
    end

    it "should handle return nil if negative index is out of range" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      value = set.delete_at(-300)
      expect(value).to be_nil
      expect(set.to_a).to eq([1, 2, 3, 4, 5])
    end
  end

  describe "set[index]" do
    it "should return the value indexed by the given index" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(set[2]).to eq(3)
    end
  end

  describe "size" do
    it "should return the number of elements in the set" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      expect(set.size).to eq(5)
    end
  end

  describe "map" do
    it "should iterate over each item in the set" do
      set = SortedContainers::SortedSet.new([1, 2, 3, 4, 5])
      items = set.map { |item| item + 1 }
      expect(items).to eq([2, 3, 4, 5, 6])
    end
  end

  describe "add" do
    it "should sort hundreds of values" do
      set = SortedContainers::SortedSet.new
      (1..1000).to_a.shuffle.each do |i|
        set.add(i)
      end
      expect(set.to_a).to eq((1..1000).to_a)
    end

    it "<< should be an alias for add" do
      set = SortedContainers::SortedSet.new
      set << 1
      set << 2
      set << 3
      expect(set.to_a).to eq([1, 2, 3])
    end
  end
end
