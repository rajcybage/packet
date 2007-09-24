class Object
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end

  def nothing?
    if respond_to?(:empty?) && respond_to?(:strip)
      empty? or strip.empty?
    elsif respond_to?(:empty?)
      empty?
    elsif respond_to?(:zero?)
      zero?
    else
      !self
    end
  end

  def clean!
    if respond_to?(:empty?) && respond_to?(:strip)
      return nil if empty?
      (strip.empty?) ? nil : (self.strip)
    elsif respond_to?(:empty?)
      empty? ? nil : self
    else
      self
    end
  end

  def blank?
    if respond_to?(:empty?) && respond_to?(:strip)
      empty? or strip.empty?
    elsif respond_to?(:empty?)
      empty?
    else
      !self
    end
  end

  def self.metaclass; class << self; self; end; end

  def self.iattr_accessor *args

    metaclass.instance_eval do
      attr_accessor *args
    end

    args.each do |attr|
      class_eval do
        define_method(attr) do
          self.class.send(attr)
        end
        define_method("#{attr}=") do |b_value|
          self.class.send("#{attr}=",b_value)
        end
      end
    end
  end
end

class NilClass #:nodoc:
  def blank?
    true
  end
end

class FalseClass #:nodoc:
  def blank?
    true
  end
end

class TrueClass #:nodoc:
  def blank?
    false
  end
end

class Array #:nodoc:
  alias_method :blank?, :empty?
  def clean!
    (empty?) ? nil : self
  end

end

class Hash #:nodoc:
  alias_method :blank?, :empty?
  def clean!
    (empty?) ? nil : self
  end
end

class String #:nodoc:
  def blank?
    empty? || strip.empty?
  end

  def clean!
    return nil if empty?
    t_val = self.strip
    (t_val.empty?) ? nil : t_val
  end
end

class Numeric #:nodoc:
  def blank?
    false
  end
end

