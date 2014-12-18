module MoneyMath
  def as_dollars(val)
    BigDecimal.new(sprintf("%.2f", val))
  end
end
