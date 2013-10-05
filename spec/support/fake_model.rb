class FakeModel
  include Multitype

  def initialize(compare = nil)
    @compare = compare
  end

  type_comparator :math, :compare

  deftype :math, 'Addition', compare: :addition do
    def run(num1, num2)
      num1 + num2
    end
  end

  deftype :math, 'Multiplication', compare: :multiplication do
    def run(num1, num2)
      num1 * num2
    end

    def message
      "Method Exists"
    end
  end

  deftype :general, 'APrefined', class: ATypeSet
  deftype :general, 'BPrefined', class: BTypeSet

  deftype :override, 'Prefined', class: BTypeSet
  deftype :override, 'Prefined', class: ATypeSet
end
