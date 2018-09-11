require "../../spec_helper"

module Amber::Validators
  describe Params do
    context "when params present" do
      it "is valid and there is no errors" do
        http_params = params_builder("number=1&name=elias&last_name=perez&middle=j")
        validator = Validators::Params.new(http_params)

        validator.validation do
          required(:number, Int32) { |v| v.is_a?(Int32) }
        end

        validator.valid?.should be_true
        validator.errors.size.should eq 0
      end
    end
  end
end
