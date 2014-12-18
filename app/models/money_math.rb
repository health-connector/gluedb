module MoneyMath
  def as_dollars(val)
    BigDecimal.new(val).round(2)
  end
end
