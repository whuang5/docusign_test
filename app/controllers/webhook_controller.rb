require 'crack'

class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    #Sample XML for testing
    #xml = '<?xml version="1.0" encoding="utf-8"?><DocuSignEnvelopeInformation xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.docusign.net/API/3.0"><EnvelopeStatus><RecipientStatuses><RecipientStatus><Type>Signer</Type><Email>williamhuang0623@gmail.com</Email><UserName>Billy Huang</UserName><RoutingOrder>1</RoutingOrder><Sent>2019-06-25T13:13:03.267</Sent><Delivered>2019-06-25T13:13:31.623</Delivered><Signed>2019-06-25T13:14:27.39</Signed><DeclineReason xsi:nil="true" /><Status>Completed</Status><RecipientIPAddress>65.223.155.202</RecipientIPAddress><CustomFields /><TabStatuses><TabStatus><TabType>SignHere</TabType><Status>Signed</Status><XPosition>839</XPosition><YPosition>568</YPosition><TabLabel>SignHereTab</TabLabel><TabName>SignHere</TabName><TabValue /><DocumentID>1</DocumentID><PageNumber>2</PageNumber></TabStatus><TabStatus><TabType>SignHere</TabType><Status>Signed</Status><XPosition>568</XPosition><YPosition>929</YPosition><TabLabel>SignHereTab</TabLabel><TabName>SignHere</TabName><TabValue /><DocumentID>1</DocumentID><PageNumber>14</PageNumber></TabStatus><TabStatus><TabType>SignHere</TabType><Status>Signed</Status><XPosition>718</XPosition><YPosition>972</YPosition><TabLabel>SignHereTab</TabLabel><TabName>SignHere</TabName><TabValue /><DocumentID>1</DocumentID><PageNumber>14</PageNumber></TabStatus></TabStatuses><AccountStatus>Active</AccountStatus><RecipientId>85b82a69-1d64-498b-84e1-5043ad9414bc</RecipientId></RecipientStatus></RecipientStatuses><TimeGenerated>2019-06-25T13:14:47.5542209</TimeGenerated><EnvelopeID>0147df4c-0144-433b-aac5-55285fe7dbbf</EnvelopeID><Subject>Sent via dummy App</Subject><UserName>William Huang</UserName><Email>william.huang5@wework.com</Email><Status>Completed</Status><Created>2019-06-25T13:13:00.813</Created><Sent>2019-06-25T13:13:03.327</Sent><Delivered>2019-06-25T13:13:31.81</Delivered><Signed>2019-06-25T13:14:27.39</Signed><Completed>2019-06-25T13:14:27.39</Completed><ACStatus>Original</ACStatus><ACStatusDate>2019-06-25T13:13:00.813</ACStatusDate><ACHolder>William Huang</ACHolder><ACHolderEmail>william.huang5@wework.com</ACHolderEmail><ACHolderLocation>DocuSign</ACHolderLocation><SigningLocation>Online</SigningLocation><SenderIPAddress>65.223.155.202 </SenderIPAddress><EnvelopePDFHash /><CustomFields /><AutoNavigation>true</AutoNavigation><EnvelopeIdStamping>true</EnvelopeIdStamping><AuthoritativeCopy>false</AuthoritativeCopy><DocumentStatuses><DocumentStatus><ID>1</ID><Name>Test</Name><TemplateName /><Sequence>1</Sequence></DocumentStatus></DocumentStatuses></EnvelopeStatus><TimeZone>Pacific Standard Time</TimeZone><TimeZoneOffset>-7</TimeZoneOffset></DocuSignEnvelopeInformation>'
    results = request.body
    parsedResults = Crack::XML.parse(results) #Parse XML --> JSON

    # Sample Parsed JSON For Reference
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

    puts "RECIPIENT STATUS"
    puts recipient_status
    puts recipient_status.is_a?(Array)
    puts "ENVELOPE_STATUS"
    puts envelope_status
    puts envelope_status.is_a?(Array)

    email = ""
    status = ""
    if recipient_status.is_a?(Array)
      email = recipient_status[0]["Email"]
      status = recipient_status[0]["Status"]
    else
      email = recipient_status["Email"]
      status = recipient_status["Status"]
    end
    email = email.downcase
    status = status.downcase

    puts "EMAIL: " + email
    puts "STATUS: " + status

    document_id = envelope_status['DocumentStatuses']['DocumentStatus']['ID']
    envelope_id = envelope_status['EnvelopeID']

    puts "DOCUMENT ID: " + document_id
    puts "ENVELOPE ID: " + envelope_id

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

    #Get Agreement variables
    @agreement = Agreement.find_by(:envelope_id => envelope_id)
    @agreement.status = status #change status to new status
    original_name = @agreement.original_name

    if status == 'completed'
      temp_file = envelope_api.get_document(account_id, document_id, envelope_id)
      id = @agreement.id

      #Move template to existing disk location
      new_file_path = "#{::Rails.root}/public/uploads/agreement/attachment/#{id}/#{original_name}_signed.pdf"
      FileUtils.cp(temp_file.path, new_file_path)
      new_file = File.new(new_file_path)

      #save new file
      @agreement.attachment = new_file #save path in database

      #delete stored temp_file
      temp_file.delete
    end

    # Save Agreement & Update agreement View
    if @agreement.save
      redirect_to agreements_path, notice: "The agreement #{@agreement.name} has been updated", turbolinks: false
    end
  end
end
