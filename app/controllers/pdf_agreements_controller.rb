class PdfAgreementsController < ApplicationController
  def new
    @agreement = Agreement.new
    @number_of_documents = [1,2,3]
  end

  def show
    @agreement = Agreement.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Invoice No. #{@agreement.id}",
               page_size: 'A4',
               template: "pdf_agreements/show.html.erb",
               layout: "pdf.html",
               orientation: "Landscape",
               lowquality: true,
               zoom: 1,
               dpi: 75,
               :extra => '--enable-forms'
      end
    end
  end

  def create
    #Create PDF with form fields using WickedPDF
    params = agreement_params
    @agreement = Agreement.new(params)

    emails = @agreement.emails
    names = @agreement.names
    orders = @agreement.orders

    #Save Agreement to generate Agreement ID
    if @agreement.save
      #Make get request to generated PDF

      pdf_string = render_to_string(:show, :locals => { :@agreement => @agreement }, layout: 'pdf')
      pdf = WickedPdf.new.pdf_from_string(
          pdf_string,
          page_size: 'A4',
          orientation: "Landscape",
          lowquality: true,
          zoom: 1,
          dpi: 75,
          :extra => '--enable-forms'
      )

      #Write PDF into temporary file on disk
      save_path = "#{::Rails.root}/public/uploads/agreement/attachment/#{@agreement.id}_tmp.pdf"
      File.open(save_path, "w:ASCII-8BIT") do
        |file|
        file.write(pdf)
      end

      #Create and save new_file in Agreements
      new_file = File.new(save_path)
      @agreement.attachment = new_file

      #Create Signers
      signers = create_signers(emails, names, orders)
      recipients_server_template = DocuSign_eSign::Recipients.new(
        :signers => signers
      )

      #Create new Doc
      doc1 = DocuSign_eSign::Document.new(
          documentBase64: Base64.encode64(File.binread(save_path)),
          documentId: '1',
          fileExtension: 'pdf',
          name: 'wework_agreement_dummy.pdf',
          transformPdfFields: "true" #important! Toggle to transform PDF Fields
      )

      # Putting it all together: Create new Composite Template (necessary for transforming PDF Fields)
      comp_template = DocuSign_eSign::CompositeTemplate.new(
          compositeTemplateId: "1",
          document: doc1,
          inlineTemplates: [
              DocuSign_eSign::InlineTemplate.new(
                sequence: '1',
                recipients: recipients_server_template
              )
          ]
      )

      notifications = DocuSign_eSign::Notification.new(
         expirations: {
             expireAfter: "120",
             expireEnabled: "true",
             expireWarn: "1"
         }
      )
      #Create Envelope Definition
      envelope_definition = DocuSign_eSign::EnvelopeDefinition.new(
        notification: notifications,
        status: "created",
        emailSubject: "WeWork Document: Please Sign This Document",
        compositeTemplates: [comp_template]
      )

      #Prepare to send new file through DocuSign
      # ENV Variables
      account_id = ENV['DOCUSIGN_ACCOUNT_ID']

      #Configure Envelopes APi
      envelopes_api = configure_envelopes_api

      #Send Document
      begin
        puts "Envelope definition params:: #{envelope_definition}"
        results = envelopes_api.create_envelope(account_id, envelope_definition)

        #Save Edit View
        return_url_request = DocuSign_eSign::ReturnUrlRequest.new(
            returnUrl: ENV['DOCUSIGN_RETURN_URL']
        )

        preview_url = get_edit_view_url(envelopes_api, account_id, results.envelope_id, return_url_request)
        puts "Pre-generated URL: " + preview_url

        @agreement.status = "created"
        @agreement.envelope_id = results.envelope_id
        @agreement.preview_url = preview_url

        puts "Envelope Results: #{results}"

        if @agreement.save
          redirect_to agreements_path, notice: "The PDF Uploaded Agreement has been saved."
        else
          render 'new'
        end
      rescue DocuSign_eSign::ApiError => e
        error = JSON.parse e.response_body
        puts "ERROR!!!!"
        puts error
      end
    end
  end

  def generate_edit_view
    #Create redirect URL
    account_id = ENV['DOCUSIGN_ACCOUNT_ID']
    @agreement = Agreement.find(params[:id])
    return_url_request = DocuSign_eSign::ReturnUrlRequest.new(
        returnUrl: ENV['DOCUSIGN_RETURN_URL']
    )
    #Configure Envelopes API
    envelopes_api = configure_envelopes_api

    #Get Edit View URL & Redirect
    edit_view_url = get_edit_view_url(envelopes_api, account_id, @agreement.envelope_id, return_url_request)
    puts "On-demand URL: #{edit_view_url}"
    redirect_to edit_view_url, notice: "The Agreement has been sent to the recipient!"
  end

  def generate_sender_view
    #Create redirect URL
    account_id = ENV['DOCUSIGN_ACCOUNT_ID']
    @agreement = Agreement.find(params[:id])
    return_url_request = DocuSign_eSign::ReturnUrlRequest.new(
        returnUrl: ENV['DOCUSIGN_RETURN_URL']
    )
    #Configure Envelopes API
    envelopes_api = configure_envelopes_api

    #Get Edit View URL & Redirect
    sender_view_url = get_sender_view_url(envelopes_api, account_id, @agreement.envelope_id, return_url_request)
    puts "On-demand URL: #{sender_view_url}"
    redirect_to sender_view_url, notice: "The Agreement has been sent to the recipient!"
  end

  def redirect_preview_url
    @agreement = Agreement.find(params[:id])
    preview_url = @agreement.preview_url
    envelope_id = @agreement.envelope_id

    #env variables
    access_token = ENV['DOCUSIGN_ACCESS_TOKEN_TEMP']
    account_id = ENV['DOCUSIGN_ACCOUNT_ID']

    #Add access token to header
    response.headers["Authorization"] = "Bearer " + access_token

    #Create Random API Call
    envelopes_api = configure_envelopes_api
    results = envelopes_api.list_documents(account_id, envelope_id)
    puts results

    redirect_to preview_url
  end

  private
  #Return Configured EnvelopesAPI client
  def configure_envelopes_api
    access_token = ENV['DOCUSIGN_ACCESS_TOKEN_TEMP']
    #Client API Config
    base_path = 'http://demo.docusign.net/restapi'
    configuration = DocuSign_eSign::Configuration.new
    configuration.host = base_path
    api_client = DocuSign_eSign::ApiClient.new(configuration)
    api_client.default_headers["Authorization"] = "Bearer " + access_token
    envelopes_api = DocuSign_eSign::EnvelopesApi.new(api_client)
  end

  #Check Required Params
  def agreement_params
    params.require(:agreement).permit(:names, :orders, :attachment, :emails, :status, :envelope_id, :number_of_docs)
  end

  #Create & Return array of signers for template usage
  def create_signers(emails, names, orders)
    e_array = emails.to_s.gsub(/\s+/, "").split(',')
    o_array = orders.to_s.gsub(/\s+/, "").split(',')
    n_array = names.to_s.split(",")
    signers = []

    if e_array.length == n_array.length
      e_array.zip(n_array, o_array).each_with_index do |val, index|
        email = val[0]
        name = val[1].strip
        order = val[2]
        new_index = index + 1

        signer = DocuSign_eSign::Signer.new({
            email: "#{email}", name: "#{name}",
            roleName: "signer", recipientId: "#{new_index}",
            routingOrder: "#{order}", #define order
            defaultRecipient: "false" #Add clientID here makes envelope embeddable
        })
        signer_tab = DocuSign_eSign::SignHere.new(
            tabLabel: "DocuSignSignHere Signer#{new_index}", #must match pdf form field name!! important
         )
        #ASSIGN Tab signing order for each recipient
        signer_tabs = DocuSign_eSign::Tabs.new(
            :signHereTabs => [signer_tab]
        )
        signer.tabs = signer_tabs
        signers.push(signer)
      end
    else
      return "error"
    end

    signers
  end

  #Get edit View URL
  def get_edit_view_url(envelopes_api, account_id, envelope_id, return_url_request)
    edit_view_results = envelopes_api.create_edit_view(account_id, envelope_id, return_url_request)
    edit_view_results.url
  end

  #Get sender View URL
  def get_sender_view_url(envelopes_api, account_id, envelope_id, return_url_request)
    sender_view_results = envelopes_api.create_sender_view(account_id, envelope_id, return_url_request)
    sender_view_results.url
  end
end
