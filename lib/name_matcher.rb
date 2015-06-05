class NameMatcher

  SUFFIXES = %w(i ii iii iv v vi vii jr sr)

  def initialize(first_name, last_name)

    @first_name = first_name.strip.downcase
    @last_name = last_name.strip.downcase
    @full_name = @first_name + @last_name
    @normalized_full_name = normalize(@full_name)
  end

  def match(test_first_name, test_last_name)

    test_full_name = (test_first_name + test_last_name).downcase
    normalized_test_full_name = normalize(test_full_name)

    return true if @normalized_full_name.eql? normalized_test_full_name # names are same

    diff = nil

    # test if difference between two name is a SUFFIX
    if(@normalized_full_name.length > normalized_test_full_name.length)
      #diff = (@normalized_full_name.split('') - normalized_test_full_name.split('')).join('')
      #puts "1 #{@normalized_full_name} #{normalized_test_full_name}"
      diff = @normalized_full_name.gsub(normalized_test_full_name,'')
    else
      #diff = (normalized_test_full_name.split('') - @normalized_full_name.split('')).join('')
      #puts "2 #{@normalized_full_name} #{normalized_test_full_name}"
      diff = normalized_test_full_name.gsub(@normalized_full_name, '')
    end

    #puts "#{diff.to_s} diff is blank? #{diff.blank?}"

    SUFFIXES.include?(diff) || diff.blank?
  end

  private

  def normalize(name)
    name.gsub(/[^a-z]/i, '')
  end
end