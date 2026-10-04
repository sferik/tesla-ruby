# frozen_string_literal: true

RSpec.describe Tesla::JSONParsing do
  subject(:parser) { Class.new { include Tesla::JSONParsing }.new }

  describe "#parse_response" do
    it "reads the response of a JSON body" do
      expect(parser.send(:parse_response, '{"response":{"name":"Nikola"}}')).to eq("name" => "Nikola")
    end

    it "raises InvalidResponse for a body without a response" do
      expect { parser.send(:parse_response, '{"name":"Nikola"}') }
        .to raise_error(Tesla::InvalidResponse, 'The response body is not the expected JSON: key not found: "response"')
    end

    it "raises InvalidResponse for a body that is not a JSON object" do
      expect { parser.send(:parse_response, "[]") }
        .to raise_error(Tesla::InvalidResponse, /\AThe response body is not the expected JSON: no implicit conversion/)
    end

    it "raises InvalidResponse for a body that is JSON without a response to fetch" do
      expect { parser.send(:parse_response, '"Nikola"') }
        .to raise_error(Tesla::InvalidResponse, /\AThe response body is not the expected JSON: undefined method 'fetch'/)
    end

    it "raises InvalidResponse for a body that is not JSON" do
      expect { parser.send(:parse_response, "<html>") }.to raise_error(Tesla::InvalidResponse, "The response body is not JSON")
    end

    it "attaches the body to the error" do
      expect { parser.send(:parse_response, "<html>") }.to raise_error(having_attributes(body: "<html>"))
    end

    it "keeps the parser error as the cause" do
      expect { parser.send(:parse_response, "<html>") }.to raise_error(having_attributes(cause: an_instance_of(JSON::ParserError)))
    end

    it "raises InvalidResponse for an empty body" do
      expect { parser.send(:parse_response, "") }.to raise_error(Tesla::InvalidResponse)
    end

    context "with a block" do
      it "returns what the block returns for the parsed JSON" do
        expect(parser.send(:parse_response, '{"response":{"name":"Nikola"}}') { |response| response.fetch("name") }).to eq("Nikola")
      end

      it "raises InvalidResponse when the block fetches a missing key" do
        expect { parser.send(:parse_response, '{"response":{}}') { |response| response.fetch("name") } }
          .to raise_error(Tesla::InvalidResponse, 'The response body is not the expected JSON: key not found: "name"')
      end

      it "raises InvalidResponse when the block calls a method the response lacks" do
        expect { parser.send(:parse_response, '{"response":"Nikola"}') { |response| response.fetch("name") } }
          .to raise_error(Tesla::InvalidResponse, /\AThe response body is not the expected JSON: undefined method 'fetch'/)
      end

      it "raises InvalidResponse when the block fetches a key from a list" do
        expect { parser.send(:parse_response, '{"response":[]}') { |response| response.fetch("name") } }
          .to raise_error(Tesla::InvalidResponse, /\AThe response body is not the expected JSON: no implicit conversion/)
      end

      it "attaches the body to the error" do
        expect { parser.send(:parse_response, '{"response":{}}') { |response| response.fetch("name") } }
          .to raise_error(having_attributes(body: '{"response":{}}'))
      end

      it "keeps the block's error as the cause" do
        expect { parser.send(:parse_response, '{"response":{}}') { |response| response.fetch("name") } }
          .to raise_error(having_attributes(cause: an_instance_of(KeyError)))
      end

      it "does not rescue other errors the block raises" do
        expect { parser.send(:parse_response, '{"response":{}}') { raise ArgumentError, "mine" } }.to raise_error(ArgumentError, "mine")
      end

      it "raises InvalidResponse for a body that is not JSON before calling the block" do
        expect { parser.send(:parse_response, "<html>") { raise "unreached" } }
          .to raise_error(Tesla::InvalidResponse, "The response body is not JSON")
      end
    end
  end
end
