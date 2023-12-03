# frozen_string_literal: true

RSpec.describe Optimistic::Json::Parser do
  let(:parser) { described_class.new }

  describe "#parse" do
    subject(:parse) { parser.parse(tokens) }

    context "with strings" do
      shared_examples "when incomplete" do
        it { is_expected.to eq(expected) }
      end

      let(:tokens) { '"I am text"' }
      let(:expected) { "I am text" }

      it { is_expected.to eq(expected) }

      it_behaves_like "when incomplete" do
        let(:tokens) { '"I am text' }
      end

      context "with single quote" do
        let(:tokens) { '"I\'m text"' }
        let(:expected) { "I'm text" }

        it { is_expected.to eq(expected) }

        it_behaves_like "when incomplete" do
          let(:tokens) { '"I\'m text' }
        end
      end

      context "when with double quotes" do
        let(:tokens) { '"I\\"m text"' }
        let(:expected) { 'I"m text' }

        it { is_expected.to eq(expected) }

        it_behaves_like "when incomplete" do
          let(:tokens) { '"I\\"m text' }
        end
      end
    end

    context "with numbers" do
      context "when positive integers" do
        let(:tokens) { "42" }

        it { is_expected.to eq(42) }
      end

      context "when negative integers" do
        let(:tokens) { "-42" }

        it { is_expected.to eq(-42) }
      end

      context "when positive floats" do
        let(:tokens) { "12.34" }

        it { is_expected.to eq(12.34) }
      end

      context "when negative floats" do
        let(:tokens) { "-12.34" }

        it { is_expected.to eq(-12.34) }
      end

      context "when incomplete positive floats" do
        let(:tokens) { "12." }

        it { is_expected.to eq(12) }
      end

      context "when incomplete negative floats" do
        let(:tokens) { "-12." }

        it { is_expected.to eq(-12) }
      end

      context "when incomplete negative integers" do
        let(:tokens) { "-" }

        it { is_expected.to eq(-0) }
      end

      context "when invalid numbers" do
        let(:tokens) { "1.2.3.4" }

        it { is_expected.to eq("1.2.3.4") }
      end
    end

    context "with bools" do
      shared_examples "when incomplete" do
        it { is_expected.to eq(expected) }
      end

      context "when true" do
        let(:tokens) { "true" }
        let(:expected) { true }

        it { is_expected.to eq(expected) }

        "true".chars.each_with_index do |_, i|
          it_behaves_like "when incomplete" do
            let(:tokens) { "true"[0..i] }
          end
        end
      end

      context "when false" do
        let(:tokens) { "false" }
        let(:expected) { false }

        it { is_expected.to eq(expected) }

        "false".chars.each_with_index do |_, i|
          it_behaves_like "when incomplete" do
            let(:tokens) { "false"[0..i] }
          end
        end
      end
    end

    context "with arrays" do
      context "when empty" do
        let(:tokens) { "[]" }
        let(:expected) { [] }

        it { is_expected.to eq(expected) }

        context "when incomplete" do
          let(:tokens) { "[" }

          it { is_expected.to eq(expected) }
        end
      end

      context "when containing strings" do
        let(:tokens) { '["str1", "str2", "str3"]' }

        it { is_expected.to eq(%w[str1 str2 str3]) }

        context "when incomplete" do
          context "with missing end bracket" do
            let(:tokens) { '["str1", "str2", "str3"' }

            it { is_expected.to eq(%w[str1 str2 str3]) }
          end

          context "with missing end quote for last item" do
            let(:tokens) { '["str1", "str2", "str3' }

            it { is_expected.to eq(%w[str1 str2 str3]) }
          end

          context "with a partial item" do
            let(:tokens) { '["str1", "str2", "st"' }

            it { is_expected.to eq(%w[str1 str2 st]) }
          end

          context "with a comma end" do
            let(:tokens) { '["str1", "str2","' }

            it { is_expected.to eq(["str1", "str2", ""]) }
          end
        end
      end

      context "when containing numbers" do
        let(:tokens) { "[1, 2, 3]" }
        let(:expected) { [1, 2, 3] }

        it { is_expected.to eq(expected) }
      end
    end

    context "with object" do
      context "when empty" do
        let(:tokens) { "{}" }

        it { is_expected.to eq({}) }
      end

      context "when simple" do
        let(:hash) { { "key1" => "val1", "key2" => "val2" } }
        let(:tokens) { hash.to_json }

        it { is_expected.to eq(hash) }
      end

      # context "when complex" do
      # end
    end
  end
end
