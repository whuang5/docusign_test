class Agreement < ActiveRecord::Base
  mount_uploader :attachment, AttachmentUploader
  validates :name, presence: true
end
