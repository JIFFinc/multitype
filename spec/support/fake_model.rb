class FakeModel
  include Multitype

  def initialize(compare)
    @compare = compare
  end

  type_dependents :math, :compare

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

  def run_type
    math.run(5, 2)
  end

  def run_message
    math.message
  end
end
