module Hamster

  class << self

    def list(*items)
      items.reverse.inject(EmptyList) { |list, item| list.cons(item) }
    end

    def stream(&block)
      block_given? or return EmptyList
      Stream.new(yield) { stream(&block) }
    end

    def interval(from, to)
      if from > to
        EmptyList
      else
        Stream.new(from) { interval(from.succ, to) }
      end
    end
    alias_method :range, :interval

  end

  module List

    def empty?
      false
    end

    def size
      tail.size + 1
    end
    alias_method :length, :size

    def cons(item)
      Sequence.new(item, self)
    end
    alias_method :>>, :cons

    def each(&block)
      block_given? or return self
      yield(head)
      tail.each(&block)
      nil
    end

    def map(&block)
      block_given? or return self
      Stream.new(yield(head)) { tail.map(&block) }
    end
    alias_method :collect, :map

    def reduce(memo)
      block_given? or return memo

      list = self
      while !list.empty?
        memo = yield(memo, list.head)
        list = list.tail
      end
      memo
    end
    alias_method :inject, :reduce

    def filter(&block)
      block_given? or return self
      if yield(head)
        Stream.new(head) { tail.filter(&block) }
      else
        tail.filter(&block)
      end
    end
    alias_method :select, :filter

    def reject(&block)
      block_given? or return self
      if yield(head)
        tail.reject(&block)
      else
        Stream.new(head) { tail.reject(&block) }
      end
    end

    def take_while(&block)
      block_given? or return self
      if yield(head)
        Stream.new(head) { tail.take_while(&block) }
      else
        EmptyList
      end
    end

    def drop_while(&block)
      block_given? or return self

      list = self
      while !list.empty? && yield(list.head)
        list = list.tail
      end
      list
    end

    def take(number)
      if number > 0
        Stream.new(head) { tail.take(number - 1) }
      else
        EmptyList
      end
    end

    def drop(number)
      list = self
      while !list.empty? && number > 0
        number -= 1
        list = list.tail
      end
      list
    end

    def include?(item)
      list = self
      while !list.empty?
        return true if item == list.head
        list = list.tail
      end
      false
    end
    alias_method :member?, :include?

    def eql?(other)
      return true if other.equal?(self)
      return false unless other.is_a?(List)
      other.head == head && other.tail.eql?(tail)
    end
    alias_method :==, :eql?

    def dup
      self
    end
    alias_method :clone, :dup

    def to_a
      reduce([]) { |a, item| a << item }
    end

    def inspect
      to_a.inspect
    end

    private

    def method_missing(name, *args, &block)
      if name.to_s =~ /^c([ad]+)r$/
        accessor($1)
      else
        super
      end
    end

    # Perform compositions of <tt>car</tt> and <tt>cdr</tt> operations. Their names consist of a 'c', followed by at
    # least one 'a' or 'd', and finally an 'r'. The series of 'a's and 'd's in each function's name is chosen to
    # identify the series of car and cdr operations that is performed by the function. The order in which the 'a's and
    # 'd's appear is the inverse of the order in which the corresponding operations are performed.
    def accessor(sequence)
      sequence.split(//).reverse!.inject(self) do |memo, char|
        case char
        when "a" then memo.head
        when "d" then memo.tail
        end
      end
    end

  end

  class Sequence

    include List

    attr_reader :head, :tail

    def initialize(head, tail)
      @head = head
      @tail = tail
    end

  end

  class Stream

    include List

    attr_reader :head

    def initialize(head, &tail)
      @head = head
      @tail = tail
    end

    def tail
      @tail.call
    end

  end

  module EmptyList

    class << self

      include List

      def head
        nil
      end

      def tail
        self
      end

      def empty?
        true
      end

      def size
        0
      end
      alias_method :length, :size

      def each
        block_given? or return self
        nil
      end

      def map
        self
      end
      alias_method :collect, :map

      def filter
        self
      end
      alias_method :select, :filter

      def reject
        self
      end

      def take_while
        self
      end

      def take(number)
        self
      end

    end

  end

end
