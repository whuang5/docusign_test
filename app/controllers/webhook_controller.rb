require 'crack'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    #Do something with webhook response
    results = request.body
    parsedResults = Crack::XML.parse(results)

    # Sample Parsed Result
    # {"DocuSignEnvelopeInformation"=>
    #   {"EnvelopeStatus"=>
    #     {"RecipientStatuses"=>
    #       {"RecipientStatus"=>
    #         {"Type"=>"Signer", "Email"=>"williamhuang0623@gmail.com",
    #           "UserName"=>"Billy Huang", "RoutingOrder"=>"1", "Sent"=>"2019-06-25T13:13:03.267",
    #           "Delivered"=>"2019-06-25T13:13:31.623", "Signed"=>"2019-06-25T13:14:27.39",
    #           "DeclineReason"=>{"xsi:nil"=>"true"}, "Status"=>"Completed",
    #           "RecipientIPAddress"=>"65.223.155.202", "CustomFields"=>nil,
    #           "TabStatuses"=> {"TabStatus"=>[
    #             {"TabType"=>"SignHere", "Status"=>"Signed", "XPosition"=>"839", "YPosition"=>"568", "TabLabel"=>"SignHereTab", "TabName"=>"SignHere", "TabValue"=>nil, "DocumentID"=>"1", "PageNumber"=>"2"},
    #             {"TabType"=>"SignHere", "Status"=>"Signed", "XPosition"=>"568", "YPosition"=>"929", "TabLabel"=>"SignHereTab", "TabName"=>"SignHere", "TabValue"=>nil, "DocumentID"=>"1", "PageNumber"=>"14"},
    #             {"TabType"=>"SignHere", "Status"=>"Signed", "XPosition"=>"718", "YPosition"=>"972", "TabLabel"=>"SignHereTab", "TabName"=>"SignHere", "TabValue"=>nil, "DocumentID"=>"1", "PageNumber"=>"14"}
    #             ]},
    #           "AccountStatus"=>"Active", "RecipientId"=>"85b82a69-1d64-498b-84e1-5043ad9414bc"
    #           }
    #         },
    #       "TimeGenerated"=>"2019-06-25T13:14:47.5542209", "EnvelopeID"=>"0147df4c-0144-433b-aac5-55285fe7dbbf",
    #       "Subject"=>"Sent via dummy App", "UserName"=>"William Huang", "Email"=>"william.huang5@wework.com",
    #       "Status"=>"Completed", "Created"=>"2019-06-25T13:13:00.813", "Sent"=>"2019-06-25T13:13:03.327", "Delivered"=>"2019-06-25T13:13:31.81",
    #       "Signed"=>"2019-06-25T13:14:27.39", "Completed"=>"2019-06-25T13:14:27.39", "ACStatus"=>"Original",
    #       "ACStatusDate"=>"2019-06-25T13:13:00.813", "ACHolder"=>"William Huang", "ACHolderEmail"=>"william.huang5@wework.com",
    #       "ACHolderLocation"=>"DocuSign", "SigningLocation"=>"Online", "SenderIPAddress"=>"65.223.155.202 ",
    #       "EnvelopePDFHash"=>nil, "CustomFields"=>nil, "AutoNavigation"=>"true", "EnvelopeIdStamping"=>"true",
    #       "AuthoritativeCopy"=>"false",
    #       "DocumentStatuses"=>{"DocumentStatus"=>{"ID"=>"1", "Name"=>"Test", "TemplateName"=>nil, "Sequence"=>"1"}}
    #       },
    #     "TimeZone"=>"Pacific Standard Time",
    #     "TimeZoneOffset"=>"-7", "xmlns:xsd"=>"http://www.w3.org/2001/XMLSchema",
    #     "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
    #     "xmlns"=>"http://www.docusign.net/API/3.0"
    #     }
    #   }

    #Get Email, Status, Document_Id, and Envelope_id from webhook response
    recipient_status = parsedResults['DocuSignEnvelopeInformation']['EnvelopeStatus']['RecipientStatuses']['RecipientStatus']
    envelope_status = parsedResults['DocuSignEnvelopeInformation']['EnvelopeStatus']

    email = recipient_status['Email'].downcase
    status = recipient_status['Status'].downcase
    document_id = envelope_status['DocumentStatuses']['DocumentStatus']["ID"]
    envelope_id = envelope_status['EnvelopeID']

    #Check if webhook response is 'completed', then get PDF based on Envelope ID
    #Docusign Configuration
    base_path = 'http://demo.docusign.net/restapi'
    account_id = ENV['DOCUSIGN_ACCOUNT_ID']
    temp_access_token = ENV['DOCUSIGN_ACCESS_TOKEN_TEMP']

    configuration = DocuSign_eSign::Configuration.new
    configuration.host = base_path
    api_client = DocuSign_eSign::ApiClient.new(configuration)
    api_client.default_headers['Authorization'] = "Bearer #{temp_access_token}"
    envelope_api = DocuSign_eSign::EnvelopesApi.new(api_client)

    #Get Agreenent variable
    @agreement = Agreement.find_by(:envelope_id => envelope_id)
    @agreement.status = status

    if status == 'completed'
      temp_file = envelope_api.get_document(account_id, document_id, envelope_id)
      file = File.new(temp_file.path)
      puts file
      @agreement.attachment = file
    end
    puts "AGREEMENT: "
    puts @agreement

    #Save Agreement & Update agreement View
    if @agreement.save
      redirect_to agreements_path, notice: "The agreement #{@agreement.name} has been upted"
    end
  end
end
