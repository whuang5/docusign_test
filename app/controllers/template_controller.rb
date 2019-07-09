class TemplateController < ApplicationController
  def new
    @agreement = Agreement.new
  end

  def create
    #sanitize params
    params = agreement_params

    #Config Variables
    email = params[:emails]
    name = params[:names]
    account_id = ENV['DOCUSIGN_ACCOUNT_ID']
    access_token = ENV['DOCUSIGN_ACCESS_TOKEN_TEMP']

    #Create Envelope with template Id
    template_id = '2d8b18cc-ef28-4058-a4e3-5fc11c6bf96e'
    envelope_definition = DocuSign_eSign::EnvelopeDefinition.new({
      :status => 'sent', :templateId => template_id
    })

    #Set Tabs Manually with Absolute Positioning
    sign_here = DocuSign_eSign::SignHere.new({
      :documentId => '1', :pageNumber => '2',
      :recipientId => '1', :tabLabel => 'SignHereTab',
      xPosition: '400', yPosition: '270'
    })
    tabs = DocuSign_eSign::Tabs.new({:signHereTabs => [sign_here]})
    signer = DocuSign_eSign::TemplateRole.new({
      :email => email, :name => name,
      :roleName => 'signer', :tabs => tabs
    });
    envelope_definition.template_roles = [signer]

    #Default configuration
    base_path = 'http://demo.docusign.net/restapi'
    configuration = DocuSign_eSign::Configuration.new
    configuration.host = base_path
    api_client = DocuSign_eSign::ApiClient.new(configuration)
    api_client.default_headers["Authorization"] = "Bearer " + access_token
    envelopes_api = DocuSign_eSign::EnvelopesApi.new(api_client)

    begin
      #send envelope
      results = envelopes_api.create_envelope(account_id, envelope_definition)

      # get envelope id from results
      envelope_id = results.envelope_id

      #get file from template
      temp_file = envelopes_api.get_document(account_id, "1", envelope_id) #default 1 is ID, testing purposes ONLY
      new_file_path = "#{::Rails.root}/public/uploads/agreement/#{envelope_id}.pdf"
      FileUtils.cp(temp_file.path, new_file_path)
      new_file = File.new(new_file_path)

      params[:attachment] = new_file
      params[:envelope_id] = envelope_id
      params[:status] = 'pending'
      @agreement = Agreement.new(params)

    rescue DocuSign_eSign::ApiError => e
      error = JSON.parse e.response_body
      puts error
    end

    if @agreement.save
      redirect_to agreements_path, notice: 'The Template Agreement has been sent'
    end
  end

  private
    def agreement_params
      params.require(:agreement).permit(:names, :attachment, :emails, :status, :envelope_id)
    end
end
