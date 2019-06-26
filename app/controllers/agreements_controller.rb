class AgreementsController < ApplicationController
  def index
    @agreements = Agreement.all
  end

  def new
    @agreement = Agreement.new
  end

  def create
    #make status pending for uploaded file
    #https://github.com/docusign/eg-03-ruby-auth-code-grant/blob/master/app/controllers/eg007_envelope_get_doc_controller.rb
    params = agreement_params
    params[:status] = "pending"

    #Set up email sending
    access_token = ENV['DOCUSIGN_ACCESS_TOKEN_TEMP']
    account_id = ENV['DOCUSIGN_ACCOUNT_ID']
    signer_name = params[:name]
    signer_email = params[:emails].downcase #Need to fix to split into multiple emails

    #Create and Save new agreement in DB
    @agreement = Agreement.new(params)

    #Get File Path & Extension
    file_path = @agreement.attachment.file.path
    file_extension = @agreement.attachment.file.extension

    #docusign config base path
    base_path = 'http://demo.docusign.net/restapi'

    #Create Envelope Definition
    envelope_definition = DocuSign_eSign::EnvelopeDefinition.new
    envelope_definition.email_subject = "Sent via dummy App"

    #create document to put inside envelope
    doc = DocuSign_eSign::Document.new({
      :documentBase64 => Base64.encode64(File.binread(file_path.to_s)),
      :name => 'Test', :fileExtension => file_extension, :documentId => '1'
    })
    envelope_definition.documents = [doc] #can include multiple documents

    #create signer
    signer = DocuSign_eSign::Signer.new({
      :email => signer_email,
      :name => signer_name,
      :recipientId => "1"
    })

    #Create sign here tab
    sign_here = DocuSign_eSign::SignHere.new({
      :documentId => '1', :pageNumber => '1',
      :recipientId => '1', :tabLabel => 'SignHereTab',
      :anchorString => 'Electronic Signature',
      :anchorYOffset => '0.25',
      :anchorXOffset => '1.5',
      :anchorUnits => 'inches'
    })
    tabs = DocuSign_eSign::Tabs.new({:signHereTabs => [sign_here]})
    signer.tabs = tabs

    #add recipient to envelope
    recipients = DocuSign_eSign::Recipients.new({:signers => [signer]})

    envelope_definition.recipients = recipients
    envelope_definition.status = 'sent' #this means send immediately

    #Send Envelope!
    configuration = DocuSign_eSign::Configuration.new
    configuration.host = base_path
    api_client = DocuSign_eSign::ApiClient.new(configuration)
    api_client.default_headers["Authorization"] = "Bearer " + access_token
    envelopes_api = DocuSign_eSign::EnvelopesApi.new(api_client)

    #Send Request to Docusign
    results = envelopes_api.create_envelope(account_id, envelope_definition)
    puts 'RESULTS'
    puts results

    params[:envelope_id] = results.envelope_id
    puts params
    #save new agreement
    @agreement = Agreement.new(params)

    if @agreement.save
      redirect_to agreements_path, notice: "The agreement #{@agreement.name} has been uploaded."
    else
      render 'new'
    end
  end

  def destroy
    @agreement = Agreement.find(params[:id])
    @agreement.destroy
    redirect_to agreements_path, notice: "The agreement #{@agreement.name} has been deleted"
  end

  private
    def agreement_params
      params.require(:agreement).permit(:name, :attachment, :emails, :status, :envelope_id)
    end
end
