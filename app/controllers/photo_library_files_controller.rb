# frozen_string_literal: true

# Shows a photo library file when they are kept on disk rather than in S3, as in
# development. Only the versions made for showing, never a photo as sent.
class PhotoLibraryFilesController < ApplicationController
  def show
    blob = ActiveStorage::Blob.find_by!(key: "#{PhotoLibrary::PUBLIC_PREFIX}#{params[:key]}")
    redirect_to rails_blob_path(blob, disposition: :inline)
  end
end
