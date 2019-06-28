class Agreement < ActiveRecord::Base
  mount_uploader :attachment, AttachmentUploader
  before_save :update_attachment_attributes
  validates :name, presence: true

  private
    def update_attachment_attributes
      if attachment.present? && attachment_changed?
        if attachment.file.content_type
          self[:content_type] = attachment.file.content_type
        end
        if attachment.file.size
          self[:file_size] = attachment.file.size
        end
        if attachment.file.original_filename
          self[:original_name] = attachment.file.original_filename
        end
      end
    end

end
