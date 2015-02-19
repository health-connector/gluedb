class NameMatcher

  SUFFIXES = %w(i ii iii iv v vi vii viii x jr sr)

  def initialize(first_name, last_name)

    @first_name = first_name.strip.downcase
    @last_name = last_name.strip.downcase
    @full_name = @first_name + " " + @last_name
  end


  def match(test_first_name, test_last_name)
      test_first_name = test_first_name.downcase
      test_last_name = test_last_name.downcase

      test_full_name = test_first_name.strip + " " + test_last_name.strip

      test_full_name = test_full_name.downcase

      return true if @full_name.eql?(test_full_name) # both names exactly same

      return true if @full_name.gsub(/[-.]/,' ').gsub('  ', ' ').eql?(test_full_name.gsub(/[-.]/,' ').gsub('  ', ' ')) # both names same after removing '-'

      return false unless @first_name.eql?(test_first_name)

      if(@last_name.length > test_last_name.length)
        diff = @last_name.split('') - test_last_name.split('') # convert to array and subtract to get difference
      else
        diff = test_last_name.split('') - @last_name.split('') # convert to array and subtract to get difference
      end

      diff = diff.join('').strip.gsub('.','') # remove any '.'

      diff = diff.split(' ') #array will include one or more suffixes e.g. iii jr

      SUFFIXES.length > (SUFFIXES - diff).length
  end
end