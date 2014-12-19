module MoneyMath
  def as_dollars(val)
    BigDecimal.new(val.to_s).round(2)
  end
end
