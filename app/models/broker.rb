class Broker
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Mongoid::Paranoia
  include MergingModel

  extend Mongorder

  field :b_type, type: String
  field :name_pfx, as: :prefix, type: String, default: ""
  field :name_first, as: :given_name, type: String
  field :name_middle, type: String, default: ""
  field :name_last, as: :surname, type: String
  field :name_sfx, as: :suffix, type: String, default: ""
  field :name_full, type: String
  field :alternate_name, type: String, default: ""
  field :npn, type: String

  has_many :policies, order: {name_last: 1, name_first: 1}
  has_many :people

  ####move
  has_many :employers
  #####
  has_many :plan_years
  
  has_and_belongs_to_many :carriers

  embeds_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: :all_blank, allow_destroy: true

  embeds_many :phones
  accepts_nested_attributes_for :phones, reject_if: :all_blank, allow_destroy: true

  embeds_many :emails
  accepts_nested_attributes_for :emails, reject_if: :all_blank, allow_destroy: true

  validates_inclusion_of :b_type, in: ["broker", "tpa"]

  index({:npn => 1})

  before_save :initialize_name_full

  scope :by_name, order_by(name_last: 1, name_first: 1)

  def self.default_search_order
    [
      ["name_last", 1],
      ["name_first", 1]
    ]
  end

  def self.search_hash(s_str)
    clean_str = s_str.strip
    s_rex = Regexp.new(Regexp.escape(clean_str), true)
    additional_exprs = []
    if clean_str.include?(" ")
      parts = clean_str.split(" ").compact
      first_re = Regexp.new(Regexp.escape(parts.first), true)
      last_re = Regexp.new(Regexp.escape(parts.last), true)
      additional_exprs << {:name_first => first_re, :name_last => last_re}
    end
    {
      "$or" => ([
        {"name_first" => s_rex},
        {"name_middle" => s_rex},
        {"name_last" => s_rex},
        {"npn" => s_rex}
      ] + additional_exprs)
    }
  end

  def self.find_or_create(m_broker)
    found_broker = Broker.find_by_npn(m_broker.npn)
    if found_broker.nil?
      m_broker.save!
      return m_broker
    else
      found_broker.merge_without_blanking(m_broker,
        :b_type,
        :name_pfx,
        :name_first,
        :name_middle,
        :name_last,
        :name_sfx,
        :name_full,
        :npn
        )

      m_broker.addresses.each { |a| found_broker.merge_address(a) }
      m_broker.emails.each { |e| found_broker.merge_email(e) }
      m_broker.phones.each { |p| found_broker.merge_phone(p) }

      found_broker.save!

      return found_broker
    end
  end

  def self.find_or_create_without_merge(m_broker)
    found_broker = Broker.find_by_npn(m_broker.npn)
    if found_broker.nil?
      m_broker.save!
      return m_broker
    end
    found_broker
  end

  def self.find_by_npn(number)
    if(number.blank?)
      return nil
    else
      Broker.where({npn: number}).first
    end
  end

  def merge_address(m_address)
    unless (self.addresses.any? { |a| a.match(m_address) })
      self.addresses << m_address
    end
  end

  def merge_email(m_email)
    unless (self.emails.any? { |e| e.match(m_email) })
      self.emails << m_email
    end
  end

  def merge_phone(m_phone)
    unless (self.phones.any? { |p| p.match(m_phone) })
      self.phones << m_phone
    end
  end

  def full_name
    [name_pfx, name_first, name_middle, name_last, name_sfx].reject(&:blank?).join(' ').downcase.gsub(/\b\w/) {|first| first.upcase }
  end

private

  def initialize_name_full
    self.name_full = full_name
  end

end
