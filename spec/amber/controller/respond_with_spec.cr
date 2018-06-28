require "../../../spec_helper"

module Amber::Controller
  describe Base do
    describe "#respond_with" do
      context "for HTML" do
        subject = setup_subject
        expected_html_content = "<html><body><h1>Elorest <3 Amber</h1></body></html>"

        it "returns `text/html` content" do
          assert_response(subject, "text/html", 200, expected_html_content)

          subject.request.headers["Accept"] = "*/*"
          assert_response(subject, "text/html", 200, expected_html_content)

          subject.request.headers["Accept"] = "text/html"
          assert_response(subject, "text/html", 200, expected_html_content)
        end

        it "returns `text/html` content for .html path extension" do
          subject.request.path = "/response/1.html"

          assert_response(subject, "text/html", 200, expected_html_content)

          subject.request.path = "/response/1.htm"
          subject.request.headers["Accept"] = "application/xml"

          assert_response(subject, "text/html", 200, expected_html_content)
        end
      end

      context "for JSON" do
        subject = setup_subject
        expected_json_content = %({"type":"json","name":"Amberator"})

        it "returns `application/json` content" do
          subject.request.headers["Accept"] = "application/json"
          assert_response(subject, "application/json", 200, expected_json_content)

          subject.request.headers["Accept"] = "application/json,*/*"
          assert_response(subject, "application/json", 200, expected_json_content)
        end

        it "returns `application/json` content for .json path extension" do
          subject.request.path = "/response/1.json"
          subject.request.headers["Accept"] = "application/xml"

          assert_response(subject, "application/json", 200, expected_json_content)
        end
      end

      context "for XML" do
        subject = setup_subject
        expected_xml_content = "<xml><body><h1>Sort of xml</h1></body></xml>"

        it "returns `application/xml` content" do
          subject.request.headers["Accept"] = "application/xml"

          assert_response(subject, "application/xml", 200, expected_xml_content)
        end

        it "returns `application/xml` content for .xml path extension" do
          subject.request.path = "/response/1.xml"

          assert_response(subject, "application/xml", 200, expected_xml_content)
        end
      end

      context "for TEXT" do
        subject = setup_subject
        expected_text_content = "Hello I'm text!"

        it "returns `text/plain` content" do
          subject.request.headers["Accept"] = "text/plain"

          assert_response(subject, "text/plain", 200, expected_text_content)
        end

        it "returns `text/plain` for TEXT path extensions" do
          subject.request.path = "/response/1.txt"
          assert_response(subject, "text/plain", 200, expected_text_content)

          subject.request.path = "/response/1.text"
          assert_response(subject, "text/plain", 200, expected_text_content)
        end
      end

      it "returns Response Not Acceptable when Text is not accepted" do
        expected_content = "Response Not Acceptable."
        subject = setup_subject
        subject.request.path = "/response/1.text"

        subject.show.should eq expected_content
        subject.response.status_code.should eq 406
      end

      it "returns default content type for invalid extension and undefined Accept header" do
        subject = setup_subject
        subject.request.path = "/response/1.invalid"
        subject.request.headers.delete("Accept")

        assert_response(subject, "text/html", 200, "<html><body><h1>Elorest <3 Amber</h1></body></html>")
      end

      it "returns Accept header content for invalid extension" do
        subject = setup_subject
        subject.request.headers["Accept"] = "application/json"
        subject.request.path = "/response/1.invalid_extension"

        assert_response(subject, "application/json", 200, %({"type":"json","name":"Amberator"}))
      end

      it "returns `text/html` content for invalid Accept header and having */* at end" do
        subject = setup_subject
        subject.request.headers["Accept"] = "unsupported/extension,*/*"

        assert_response(subject, "text/html", 200, "<html><body><h1>Elorest <3 Amber</h1></body></html>")
      end

      it "responds with 403 custom status_code" do
        subject = setup_subject
        subject.request.headers["Accept"] = "application/json"

        subject.custom_status_code.should eq %({"type":"json","error":"Unauthorized"})
        subject.response.headers["Content-Type"].should eq "application/json"
        subject.response.status_code.should eq 403
      end

      it "responds with html from a proc" do
        subject = setup_subject
        subject.response.status_code = 200
        subject.request.headers["Accept"] = "text/html"

        subject.proc_html.should eq "<html><body><h1>Elorest <3 Amber</h1></body></html>"
        subject.response.headers["Content-Type"].should eq "text/html"
        subject.response.status_code.should eq 200
      end

      context "Redirects" do
        subject = setup_subject
        
        it "redirects from a proc" do
          subject.response.status_code = 200
          subject.request.headers["Accept"] = "text/html"

          subject.proc_redirect.should eq "302"
          subject.response.headers["Location"].should eq "/some_path"
          subject.response.status_code.should eq 302
        end

        it "redirects with flash from a proc" do
          subject.response.status_code = 200
          subject.request.headers["Accept"] = "text/html"

          subject.proc_redirect_flash.should eq "302"
          subject.flash["success"].should eq "amber is the bizness"
          subject.response.headers["Location"].should eq "/some_path"
          subject.response.status_code.should eq 302
        end

        it "redirects with a status code from a proc" do
          subject.response.status_code = 200
          subject.request.headers["Accept"] = "text/html"
          subject.proc_perm_redirect.should eq "301"

          subject.response.headers["Location"].should eq "/some_path"
          subject.response.status_code.should eq 301
        end
      end
    end
  end
end

def setup_subject
  request = HTTP::Request.new("GET", "")
  request.headers["Accept"] = ""
  context = create_context(request)
  ResponsesController.new(context)
end

def assert_response(subject, content_type, status_code, expected_content)
  subject.index.should eq expected_content
  subject.response.headers["Content-Type"].should eq content_type
  subject.response.status_code.should eq status_code
end
