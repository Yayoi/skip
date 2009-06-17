# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

module ValidationsFile
  def valid_presence_of_file(file)
    unless file.is_a?(ActionController::UploadedFile)
      errors.add_to_base _("No files marked for upload.")
      return false
    end
    true
  end

  def valid_extension_of_file(file)
    unless SkipUtil.verify_extension? file.original_filename, file.content_type
      errors.add_to_base _("Files of this format are not accepted.")
    end
  end

  def valid_size_of_file(file)
    if file.size == 0
      errors.add_to_base _("Nonexistent or empty files are not accepted for uploading.")
    elsif file.size > INITIAL_SETTINGS['max_share_file_size'].to_i
      errors.add_to_base _("Files larger than %dMBytes are not permitted.") % INITIAL_SETTINGS['max_share_file_size'].to_i/1.megabyte
    end
  end

  def valid_max_size_per_owner_of_file(file, owner_symbol)
    if (FileSizeCounter.per_owner(owner_symbol) + file.size) > INITIAL_SETTINGS['max_share_file_size_per_owner'].to_i
      errors.add_to_base _("Upload denied due to excess of assigned shared files disk capacity.")
    end
  end

  def valid_max_size_of_system_of_file(file)
    if (FileSizeCounter.per_system + file.size) > INITIAL_SETTINGS['max_share_file_size_of_system'].to_i
      errors.add_to_base _("Upload denied due to excess of system wide shared files disk capacity.")
    end
  end

  class FileSizeCounter
    def self.per_owner owner_symbol
      sum = 0
      sum += ShareFile.total_share_file_size(owner_symbol)
      sum += BoardEntry.total_image_size(owner_symbol)
      sum
    end
    def self.per_system
      sum = 0
      Dir.glob("#{ENV['SHARE_FILE_PATH']}/**/*\0#{ENV['IMAGE_PATH']}/**/*").each do |f|
        sum += File.stat(f).size
      end
      sum
    end
  end
end
