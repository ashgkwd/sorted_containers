# frozen_string_literal: true

# The SortedContainers module provides data structures for sorted collections.
module SortedContainers
  # The SortedArray class is a sorted array implementation.
  # rubocop:disable Metrics/ClassLength
  class SortedArray
    include Enumerable

    DEFAULT_LOAD_FACTOR = 1000

    attr_reader :size

    # Initializes a new SortedArray object.
    #
    # @param iterable [Enumerable] An optional iterable object to initialize the array with.
    # @param load_factor [Integer] The load factor for the array.
    def initialize(iterable = [], load_factor: DEFAULT_LOAD_FACTOR)
      @lists = []
      @maxes = []
      @index = []
      @offset = 0
      @load_factor = load_factor
      @size = 0
      update(iterable)
    end

    # Adds a value to the sorted array.
    #
    # @param value [Object] The value to add.
    # rubocop:disable Metrics/MethodLength
    def add(value)
      if @maxes.empty?
        @lists.append([value])
        @maxes.append(value)
      else
        pos = internal_bisect_right(@maxes, value)
        if pos == @maxes.size
          pos -= 1
          @lists[pos].push(value)
          @maxes[pos] = value
        else
          sub_pos = internal_bisect_right(@lists[pos], value)
          @lists[pos].insert(sub_pos, value)
        end
        expand(pos)
      end
      @size += 1
    end
    # rubocop:enable Metrics/MethodLength

    # Alias for add
    #
    # @param value [Object] The value to add.
    def <<(value)
      add(value)
    end

    # Checks if Array is empty
    #
    # @return [Boolean]
    def empty?
      @size.zero?
    end

    # Returns an index to insert `value` in the sorted list.
    #
    # If the `value` is already present, the insertion point will be before
    # (to the left of) any existing values.
    #
    # Runtime complexity: `O(log(n))` -- approximate.
    #
    # sl = SortedList.new([10, 11, 12, 13, 14])
    # sl.bisect_left(12)
    # 2
    #
    # @param value [Object] The value to insert.
    # @return [Integer] The index to insert the value.
    def bisect_left(value)
      return 0 if @maxes.empty?

      pos = internal_bisect_left(@maxes, value)

      return @size if pos == @maxes.size

      idx = internal_bisect_left(@lists[pos], value)
      loc(pos, idx)
    end

    # Returns an index to insert `value` in the sorted list.
    #
    # If the `value` is already present, the insertion point will be after
    # (to the right of) any existing values.
    #
    # Runtime complexity: `O(log(n))` -- approximate.
    #
    # sl = SortedList.new([10, 11, 12, 13, 14])
    # sl.bisect_right(12)
    # 3
    #
    # @param value [Object] The value to insert.
    # @return [Integer] The index to insert the value.
    def bisect_right(value)
      return 0 if @maxes.empty?

      pos = internal_bisect_right(@maxes, value)

      return @size if pos == @maxes.size

      idx = internal_bisect_right(@lists[pos], value)
      loc(pos, idx)
    end

    # Deletes a value from the sorted array.
    #
    # @param value [Object] The value to delete.
    def delete(value)
      return if @maxes.empty?

      pos = internal_bisect_left(@maxes, value)

      return if pos == @maxes.size

      idx = internal_bisect_left(@lists[pos], value)

      internal_delete(pos, idx) if @lists[pos][idx] == value
    end

    # Tries to match the behavior of Array#[]
    #
    # @param args [Integer, Range, Enumerator::ArithmeticSequence] The index or range of values to retrieve.
    # @return [Object, Array] The value or values at the specified index or range.
    # rubocop:disable Metrics/MethodLength
    def [](*args)
      case args.size
      when 1
        arg = args[0]
        case arg
        when Integer
          get_value_at_index(arg)
        when Range
          get_values_from_range(arg)
        when Enumerator::ArithmeticSequence
          get_values_from_arithmetic_sequence(arg)
        else
          raise TypeError, "no implicit conversion of #{arg.class} into Integer"
        end
      when 2
        start, length = args
        get_values_from_start_and_length(start, length)
      else
        raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 1..2)"
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Retrieves the last value in the sorted array.
    #
    # @return [Object] The last value in the array.
    def last
      raise "Array is empty" if @size.zero?

      @lists.last.last
    end

    # Retrieves the first value in the sorted array.
    #
    # @return [Object] The first value in the array.
    def first
      raise "Array is empty" if @size.zero?

      @lists.first.first
    end

    # Deletes the value at the specified index.
    #
    # @param index [Integer] The index of the value to delete.
    def delete_at(index)
      pos, idx = pos(index)
      internal_delete(pos, idx)
    end

    # Pops the last value from the sorted array.
    #
    # @return [Object] The last value in the array.
    def pop
      raise "Array is empty" if @size.zero?

      value = @lists.last.pop
      if @lists.last.empty?
        @lists.pop
        @maxes.pop
      else
        @maxes[-1] = @lists.last.last
      end
      @size -= 1
      value
    end

    # Clears the sorted array, removing all values.
    def clear
      @lists.clear
      @maxes.clear
      @index.clear
      @offset = 0
      @size = 0
    end

    # Checks if the sorted array contains a value.
    #
    # @param value [Object] The value to check.
    # @return [Boolean] True if the value is found, false otherwise.
    def include?(value)
      i = internal_bisect_left(@maxes, value)
      return false if i == @maxes.size

      sublist = @lists[i]
      idx = internal_bisect_left(sublist, value)
      idx < sublist.size && sublist[idx] == value
    end

    # Updates the sorted array with values from an iterable object.
    #
    # @param iterable [Enumerable] The iterable object to update the array with.
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def update(iterable)
      values = iterable.to_a.sort
      if @maxes.any?
        if values.size * 4 >= @size
          @lists.append(values)
          values = @lists.flatten.sort
          clear
        else
          values.each { |value| add(value) }
          return
        end
      end

      values.each_slice(@load_factor) do |slice|
        @lists.append(slice)
        @maxes.append(slice.last)
      end
      @size = values.size
      @index.clear
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    # Converts the sorted array to an array.
    #
    # @return [Array] An array representation of the sorted array.
    def to_a
      @lists.flatten
    end

    # Returns the maximum value in the sorted array.
    #
    # @return [Object] The maximum value in the array.
    def max
      @lists.last&.last
    end

    # Returns the minimum value in the sorted array.
    #
    # @return [Object] The minimum value in the array.
    def min
      @lists.first&.first
    end

    # Iterates over each value in the sorted array.
    #
    # @yield [value] Gives each value to the block.
    def each(&block)
      @lists.each do |sublist|
        sublist.each(&block)
      end
    end

    private

    # Performs a left bisect on the array.
    #
    # @param array [Array] The array to bisect.
    # @param value [Object] The value to bisect with.
    # @return [Integer] The index where the value should be inserted.
    def internal_bisect_left(array, value)
      array.bsearch_index { |x| x >= value } || array.size
    end

    # Performs a right bisect on the array.
    #
    # @param array [Array] The array to bisect.
    # @param value [Object] The value to bisect with.
    # @return [Integer] The index where the value should be inserted.
    def internal_bisect_right(array, value)
      array.bsearch_index { |x| x > value } || array.length
    end

    # Gets the value at a given index.
    #
    # @param index [Integer] The index to get the value from.
    def get_value_at_index(index)
      raise "Index out of range" if index.negative? || index >= @size

      @lists.each do |sublist|
        return sublist[index] if index < sublist.size

        index -= sublist.size
      end
    end

    # Gets values from a range.
    #
    # @param range [Range] The range to get values from.
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def get_values_from_range(range)
      start = range.begin
      start += @size if start.negative?
      return nil if start.negative?

      length = range.end
      length += @size if length.negative?
      length += 1 unless range.exclude_end?
      length -= start
      return nil if length.negative?

      result = []
      @lists.each do |sublist|
        if start < sublist.size
          result.concat(sublist[start, length])
          length -= sublist.size - start
          break if length <= 0

          start = 0
        else
          start -= sublist.size
        end
      end
      result
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # Gets values from an arithmetic sequence.
    #
    # @param sequence [Enumerator::ArithmeticSequence] The arithmetic sequence to get values from.
    # @return [Array] The values from the arithmetic sequence.
    # rubocop:disable Metrics/MethodLength
    def get_values_from_arithmetic_sequence(sequence)
      result = []
      sequence.each do |index|
        break if index.negative? || index >= @size

        @lists.each do |sublist|
          if index < sublist.size
            result << sublist[index]
            break
          else
            index -= sublist.size
          end
        end
      end
      result
    end
    # rubocop:enable Metrics/MethodLength

    # Gets values starting from a given index and continuing for a given length.
    #
    # @param start [Integer] The index to start from.
    # @param length [Integer] The length of the values to get.
    # @return [Array] The values starting from the given index and continuing for the given length.
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength
    def get_values_from_start_and_length(start, length)
      raise "Index out of range" if start.negative? || start >= @size

      if length.negative?
        nil
      else
        result = []
        @lists.each do |sublist|
          if start < sublist.size
            result.concat(sublist[start, length])
            length -= sublist.size - start
            break if length <= 0

            start = 0
          else
            start -= sublist.size
          end
        end
        result
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/MethodLength

    # Expands a sublist if it exceeds the load factor.
    #
    # @param sublist_index [Integer] The index of the sublist to expand.
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def expand(sublist_index)
      sublist = @lists[sublist_index]
      if sublist.size > (@load_factor << 1)
        @maxes.insert(sublist_index + 1, sublist.last)
        half = sublist.slice!(@load_factor, sublist.size - @load_factor)
        @lists.insert(sublist_index + 1, half)
        @index.clear
      elsif @index.size.positive?
        child = @offset + sublist_index
        while child.positive?
          @index[child] += 1
          child = (child - 1) >> 1
        end
        @index[0] += 1
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # Deletes a value from a sublist.
    #
    # @param pos [Integer] The index of the sublist.
    # @param idx [Integer] The index of the value to delete.
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def internal_delete(pos, idx)
      @lists[pos].delete_at(idx)
      @size -= 1
      return unless @lists[pos].size < @load_factor >> 1

      @maxes[pos] = @lists[pos].last

      if @index.size.positive?
        child = @offset + pos
        while child.positive?
          @index[child] -= 1
          child = (child - 1) >> 1
        end
        @index[0] -= 1
      elsif @lists.size > 1
        pos += 1 if pos.zero?

        prev = pos - 1
        @lists[prev].concat(@lists[pos])
        @maxes[prev] = @lists[prev].last

        @lists.delete_at(pos)
        @maxes.delete_at(pos)
        @index.clear

        expand(prev)
      elsif @lists[pos].size.positive?
        @maxes[pos] = @lists[pos].last
      else
        @lists.delete_at(pos)
        @maxes.delete_at(pos)
        @index.clear
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # Builds the positional index for indexing the sorted array.
    # Indexes are represented as binary trees in a dense array notation
    # similar to a binary heap.
    #
    # For example, given a lists representation storing integers:
    #
    #     0: [1, 2, 3]
    #     1: [4, 5]
    #     2: [6, 7, 8, 9]
    #     3: [10, 11, 12, 13, 14]
    #
    # The first transformation maps the sub-lists by their length. The
    # first row of the index is the length of the sub-lists:
    #
    #     0: [3, 2, 4, 5]
    #
    # Each row after that is the sum of consecutive pairs of the previous
    # row:
    #
    #     1: [5, 9]
    #     2: [14]
    #
    # Finally, the index is built by concatenating these lists together:
    #
    #     @index = [14, 5, 9, 3, 2, 4, 5]
    #
    # An offset storing the start of the first row is also stored:
    #
    #     @offset = 3
    #
    # When built, the index can be used for efficient indexing into the list.
    # See the comment and notes on `SortedArray#pos` for details.
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    def build_index
      row0 = @lists.map(&:size)

      if row0.size == 1
        @index = row0
        @offset = 0
        return
      end

      head = row0.each
      tail = head.each
      row1 = head.zip(tail).map { |a, b| a + b }

      row1.append(row0[-1]) if row0.size.odd?

      if row1.size == 1
        @index = row1 + row0
        @offset = 1
        return
      end

      size = 2**(Math.log(row1.size - 1, 2).to_i + 1)
      row1.concat([0] * (size - row1.size))
      tree = [row0, row1]

      while tree[-1].size > 1
        head = tree[-1].each
        tail = head.each
        row = head.zip(tail).map { |a, b| a + b }
        tree.append(row)
      end

      @index = tree.reverse.reduce(:+)
      @offset = (size * 2) - 1
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity

    # Convert an index into an index pair (lists index, sublist index)
    # that can be used to access the corresponding lists position.
    #
    # Many queries require the index be built. Details of the index are
    # described in `SortedArray#build_index`.
    #
    # Indexing requires traversing the tree to a leaf node. Each node has two
    # children which are easily computable. Given an index, pos, the
    # left-child is at `pos * 2 + 1` and the right-child is at `pos * 2 + 2`.
    #
    # When the index is less than the left-child, traversal moves to the
    # left sub-tree. Otherwise, the index is decremented by the left-child
    # and traversal moves to the right sub-tree.
    #
    # At a child node, the indexing pair is computed from the relative
    # position of the child node as compared with the offset and the remaining
    # index.
    #
    # For example, using the index from `SortedArray#build_index`:
    #
    #     index = 14 5 9 3 2 4 5
    #     offset = 3
    #
    # Tree:
    #
    #          14
    #       5      9
    #     3   2  4   5
    #
    # Indexing position 8 involves iterating like so:
    #
    # 1. Starting at the root, position 0, 8 is compared with the left-child
    #    node (5) which it is greater than. When greater the index is
    #    decremented and the position is updated to the right child node.
    #
    # 2. At node 9 with index 3, we again compare the index to the left-child
    #    node with value 4. Because the index is the less than the left-child
    #    node, we simply traverse to the left.
    #
    # 3. At node 4 with index 3, we recognize that we are at a leaf node and
    #    stop iterating.
    #
    # To compute the sublist index, we subtract the offset from the index
    # of the leaf node: 5 - 3 = 2. To compute the index in the sublist, we
    # simply use the index remaining from iteration. In this case, 3.
    #
    # The final index pair from our example is (2, 3) which corresponds to
    # index 8 in the sorted list.
    #
    # @param idx [Integer] The index in the sorted list.
    # @return [Array] The (lists index, sublist index) pair.
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    def pos(idx)
      if idx.negative?
        last_len = @lists[-1].size

        return @lists.size - 1, last_len + idx if (-idx) <= last_len

        idx += @size

        raise IndexError, "list index out of range" if idx.negative?

      elsif idx >= @size
        raise IndexError, "list index out of range"
      end

      return 0, idx if idx < @lists[0].size

      build_index if @index.empty?

      pos = 0
      child = 1
      len_index = @index.size

      while child < len_index
        index_child = @index[child]

        if idx < index_child
          pos = child
        else
          idx -= index_child

          pos = child + 1
        end

        child = (pos << 1) + 1
      end

      [pos - @offset, idx]
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

    def loc(pos, idx)
      return idx if pos.zero?

      build_index if @index.empty?

      # Increment pos to point in the index to @lists[pos].size.
      total = 0

      pos += @offset

      # Iterate until reaching the root of the index tree at pos = 0.
      while pos.positive?

        # Right-child nodes are at even indices. At such indices
        # account the total below the left child node.
        total += @index[pos - 1] if pos.odd?

        # Advance pos to the parent node.
        pos = (pos - 1) >> 1
      end

      total + idx
    end
  end
  # rubocop:enable Metrics/ClassLength
end
