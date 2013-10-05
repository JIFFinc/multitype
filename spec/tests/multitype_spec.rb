require 'spec_helper'

describe "Test the multitype" do
  it "Should evaluate 5 + 2 using a type" do
    result = FakeModel.new(:addition).math_run()
    result.should == 7
  end

  it "Should evaluate 5 * 2 using a type" do
    result = FakeModel.new(:multiplication).math_run()
    result.should == 10
  end

  it "Should not find the method `message`" do
    expect do
      FakeModel.new(:addition).math_message()
    end.to raise_error
  end

  it "Should find the method `message`" do
    result = FakeModel.new(:multiplication).math_message()
    result.should == "Method Exists"
  end

  it "Should allow use of a predefined class inside the type" do
    result = FakeModel.new.general_run()
    result.should == :works
  end

  it "Should run the first defined typeset if there is no comparator" do
    result = FakeModel.new.general_run()
    result.should == :works
  end

  it "Should override typeset if you redeclare with the same name" do
    result = FakeModel.new.override_run()
    result.should == :works
  end
end
