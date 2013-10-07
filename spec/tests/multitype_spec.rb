require 'spec_helper'

describe "Test the multitype with FakeModel" do
  it "Should evaluate 5 + 2 using a type" do
    result = FakeModel.new(:addition).math.run(5, 2)
    result.should == 7
  end

  it "Should evaluate 5 * 2 using a type" do
    result = FakeModel.new(:multiplication).math.run(5, 2)
    result.should == 10
  end

  it "Should not find the method `message`" do
    expect do
      FakeModel.new(:addition).math.message()
    end.to raise_error
  end

  it "Should find the method `message`" do
    result = FakeModel.new(:multiplication).math.message()
    result.should == "Method Exists"
  end

  it "Should allow use of a predefined class inside the type" do
    result = FakeModel.new.general.run()
    result.should == :works
  end

  it "Should run the first defined typeset if there is no comparator" do
    result = FakeModel.new.general.run()
    result.should == :works
  end

  it "Should override typeset if you redeclare with the same name" do
    result = FakeModel.new.override.run()
    result.should == :works
  end

  it "Should use a hash for comparing multiple typesets 1" do
    result = FakeModel.new(:tree).apple.run()
    result.should == :tree
  end

  it "Should use a hash for comparing multiple typesets 2" do
    result = FakeModel.new(:pie).apple.run()
    result.should == :pie
  end
end

describe "Test the multitype with FakeModel2 (inherits FakeModel)" do
  it "Should evaluate 5 + 2 using a type (inherited from FakeModel)" do
    result = FakeModel2.new(:addition).math.run(5, 2)
    result.should == 7
  end

  it "Should evaluate 5 * 2 using a type (inherited from FakeModel)" do
    result = FakeModel2.new(:multiplication).math.run(5, 2)
    result.should == 10
  end

  it "Should define a new type `pizza` on FakeModel2" do
    result = FakeModel2.new.pizza.run()
    result.should == :pizza
  end

  it "Should use alias defined for `pizza`" do
    result = FakeModel2.new.sauce.run()
    result.should == :pizza
  end

  it "Pizza should not exist on FakeModel" do
    expect do
      FakeModel.new.pizza.run()
    end.to raise_error
  end
end
