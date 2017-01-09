# A window iterator for arrays.
class ArrayWindow
  include Enumerable

  def initialize(source_array)
    @array = source_array 
  end

  def each
    @array.each_index do |i|
      head = @array.first(i)
      element = @array[i]
      tail = @array[(i+1)..-1]
      yield [element, head, tail]
    end
  end
end
