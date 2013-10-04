require 'spec_helper'

describe "Test the multitype" do
  it "Should evaluate 5 + 2 using a type" do
    result = FakeModel.new(:addition).run_type()
    result.should == 7
  end

  it "Should evaluate 5 * 2 using a type" do
    result = FakeModel.new(:multiplication).run_type()
    result.should == 10
  end

  it "Should not find the method `message`" do
    expect do
      FakeModel.new(:addition).run_message()
    end.to raise_error
  end

  it "Should find the method `message`" do
    result = FakeModel.new(:multiplication).run_message()
    result.should == "Method Exists"
  end
end
