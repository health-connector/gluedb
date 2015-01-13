class IndividualQualifyingLifeEvent < QualifyingLifeEvent

	INDIVIDUAL_QLES = %W[
		adoption
		birth
		contract_violation
		death
		divorce
		eligibility_change_assistance
		eligibility_change_employer_ineligible
		eligibility_change_medicaid_ineligible
		enrollment_error_or_misconduct_hbx
		enrollment_error_or_misconduct_issuer
		enrollment_error_or_misconduct_non_hbx
		exceptional_circumstances
		exceptional_circumstances_civic_service
		exceptional_circumstances_domestic_abuse
		exceptional_circumstances_hardship_exemption
		exceptional_circumstances_medical_emergency
		exceptional_circumstances_natural_disaster
		exceptional_circumstances_system_outage
		foster_care
		immigration_status_change
		location_change
		lost_access_to_mec
		marriage
		qualified_native_american
		termination_of_benefits
	]

	validates_presence_of :start_date, :end_date
  embedded_in :application_group

end