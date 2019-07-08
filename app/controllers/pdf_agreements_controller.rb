class PdfAgreementsController < ApplicationController
  def new
    @agreement = Agreement.new
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

    signer1_email = @agreement.emails
    signer1_name = @agreement.name

    #Save Agreement to generate Agreement ID
    if @agreement.save
      #Make get request to generated PDF
      # OLD GET REQUEAT
      # client = HTTPClient.new
      # pdf = client.get_content("#{request.base_url}/pdf_agreements/#{@agreement.id}.pdf")

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

      #Define Signers, High Level
      signer1 = DocuSign_eSign::Signer.new({
          email: signer1_email, name: signer1_name,
          roleName: "signer", recipientId: "1",
          routingOrder: '1' #define order
           #Adding clientUserId transforms the template recipient into an embedded recipient, not done now because we are email-sending
       })

      #Define Signer Tabs & Assign Signing Order
      signer1_tab = DocuSign_eSign::SignHere.new(
          tabLabel: "SignHere" #must match pdf form field name!! important
       )
      signer1_tabs = DocuSign_eSign::Tabs.new(
          :signHereTabs => signer1_tab
      )
      signer1.tabs = signer1_tabs
      recipients_server_template = DocuSign_eSign::Recipients.new(
        "signer" => [signer1]
      )

      #Create new Doc
      doc1 = DocuSign_eSign::Document.new(
          'documentBase64': Base64.encode64(File.binread(save_path)),
          'documentId': '1',
          'fileExtension': 'pdf',
          'name': 'wework_agreement_dummy.pdf',
          'transformPdfFields': true #important! Toggle to transform PDF Fields
      )

      # Putting it all together: Create new Composite Template (necessary for transforming PDF Fields)
      comp_template = DocuSign_eSign::CompositeTemplate.new(
          compositeTemplateId: "1",
          inlineTemplates: [
              DocuSign_eSign::InlineTemplate.new(
                sequence: '1',
                recipients: recipients_server_template
              )
          ],
          document: doc1
      )

      #Create Envelope Definition
      envelope_definition = DocuSign_eSign::EnvelopeDefinition.new(
        status: "sent",
        emailSubject: "WeWork Document: Please Sign This Document",
        compositeTemplates: [comp_template]
      )

      #Prepare to send new file through DocuSign
      # ENV Variables
      access_token = ENV['DOCUSIGN_ACCESS_TOKEN_TEMP']
      account_id = ENV['DOCUSIGN_ACCOUNT_ID']
      #Client API Config
      base_path = 'http://demo.docusign.net/restapi'
      configuration = DocuSign_eSign::Configuration.new
      configuration.host = base_path
      api_client = DocuSign_eSign::ApiClient.new(configuration)
      api_client.default_headers["Authorization"] = "Bearer " + access_token
      envelopes_api = DocuSign_eSign::EnvelopesApi.new(api_client)

      #Send Document
      begin
        results = envelopes_api.create_envelope(account_id, envelope_definition)
      rescue DocuSign_eSign::ApiError => e
        error = JSON.parse e.response_body
        puts "ERROR!!!!"
        puts error
      end
    end

  end

  private
  def agreement_params
    params.require(:agreement).permit(:name, :attachment, :emails, :status, :envelope_id)
  end
end