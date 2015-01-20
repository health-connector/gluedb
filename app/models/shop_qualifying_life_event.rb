class ShopQualifyingLifeEvent < QualifyingLifeEvent

	SHOP_QLES = %W[
		adoption
		birth
		contract_violation
		death
		divorce
		exceptional_circumstances
		location_change
		lost_access_to_mec
		marriage
		termination_of_benefits
	]

  embedded_in :family

end