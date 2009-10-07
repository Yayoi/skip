# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
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

class UserMailer::AR < UserMailer::Base
  self.delivery_method = Admin::Setting.mail_function_setting ? :activerecord : :test

  def sent_contact(recipient, user_name, entry_url, entry_title)
    if recipient.include? ","
      @bcc        = recipient
    else
      @recipients = recipient
    end
    @subject    = UserMailer::Base.base64(_("[%{title}] You have a message from %{user}.") % {:title => Admin::Setting.abbr_app_title, :user => user_name})
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:name => user_name, :entry_url => entry_url, :entry_title => entry_title, :header => header, :footer => footer}
  end

  def sent_message(recipient, link_url, message ,message_manage_url)
    @recipients = recipient
    @subject    = UserMailer::Base.base64("[#{Admin::Setting.abbr_app_title}] #{message}")
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:link_url => link_url, :message => message, :message_manage_url => message_manage_url, :header => header, :footer => footer}
  end
end
