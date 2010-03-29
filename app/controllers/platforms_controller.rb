# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

class PlatformsController < ApplicationController
  layout 'not_logged_in'
  skip_before_filter :sso, :login_required, :prepare_session, :valid_tenant_required
  skip_before_filter :verify_authenticity_token, :only => :reset_openid

  before_filter :require_not_login, :except => [:logout]

  def show
    response.headers['X-XRDS-Location'] = server_url(:format => :xrds, :protocol => scheme)
    img_files = Dir.glob(File.join(RAILS_ROOT, "public", "custom", "images", "titles", "background*.{jpg,png,jpeg}"))
    @img_name = File.join("titles", File.basename(img_files[rand(img_files.size)]))
    respond_to do |format|
      format.html { render 'index' }
    end
  end

  def require_login
  end

  # ログイン処理（トップからと、require_loginからの両方からpostされる）
  # 認証後は、戻り先がある場合はそちらへ、なければデフォルトはSKIPへ遷移
  def login
    if using_open_id?
      login_with_open_id
    else
      login_with_password
    end
  end

  # ログアウト
  def logout
    logout_killing_session!
    notice = _('You are now logged out.')
    notice = notice + "<br>" + _('You had been retired.') unless params[:message].blank?
    flash[:notice] = notice

    # TODO: OP連携のlogout時にOPのログアウトに飛ばすか？
    redirect_to platform_url
  end

  def forgot_password
    unless enable_forgot_password?
      render_404 and return
    end
    return unless request.post?
    email = params[:email]
    if email.blank?
      flash.now[:error] = _('Email is mandatory.')
      return
    end
    if @user = User.find_by_email(email)
      if @user.active?
        @user.issue_reset_auth_token
        @user.save_without_validation!
        UserMailer::Smtp.deliver_sent_forgot_password(current_tenant, email, reset_password_url(@user.reset_auth_token))
        flash[:notice] = _("An email contains the URL for resetting the password has been sent to %s.") % email
        redirect_to [current_tenant, :platform]
      else
        flash.now[:error] = _('User has entered email address %s is not in use. Please start with the site.') % email
      end
    else
      flash.now[:error] = _("Entered email address %s has not been registered in the site.") % email
    end
  end

  def reset_password
    if @user = User.find_by_reset_auth_token(params[:code])
      if Time.now <= @user.reset_auth_token_expires_at
        return unless request.post?
        @user.crypted_password = nil
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
        if @user.save
          flash[:notice] = _("Password was successfully reset.")
          redirect_to [current_tenant, :platform]
        else
          flash.now[:error] = _("Failed to reset password.")
        end
      else
        flash[:error] = _("The URL for resetting password has already expired.")
        redirect_to [current_tenant, :platform]
      end
    else
      flash[:error] = _("Invalid password reset URL. Try again or contact system administrator.")
      redirect_to [current_tenant, :platform]
    end
  end

  def activate
    unless enable_activate?
      flash[:error] = _('%{function} currently unavailable.') % {:function => _('Activation email')}
      return redirect_to [current_tenant, :platform]
    end
    return unless request.post?
    email = params[:email]
    if email.blank?
      flash.now[:error] = _('Email address is mandatory.')
      return
    end
    if @user = User.scoped(:conditions => ['email = ?', email]).find_without_retired_skip(:first)
      if  @user.unused?
        @user.issue_activation_code
        @user.save_without_validation!
        UserMailer::Smtp.deliver_sent_activate(current_tenant, email, @user, signup_url(@user.activation_token))
        flash[:notice] = _("An email containing the URL for signup will be sent to %{email}.") % {:email => email}
        redirect_to [current_tenant, :platform]
      else
        flash.now[:error] =_("Email address %s has been registered in the site") % email
      end
    else
      flash.now[:error] = _("Entered email address %s has not been registered in the site.") % email
    end
  end

  def signup
    unless enable_signup?
      flash[:error] = _('%{function} currently unavailable.') % {:function => _('User registration')}
      return redirect_to platform_url
    end
    if @user = User.find_by_activation_token(params[:code])
      if @user.within_time_limit_of_activation_token?
        self.current_user = @user
        redirect_to new_tenant_user_url(current_tenant)
      else
        flash[:error] = _("The URL for registration has already expired.")
        redirect_to platform_url
      end
    else
      flash[:error] = _("Invalid registration URL. Try again or contact system administrator.")
      redirect_to platform_url
    end
  end

  def reset_openid
    if user = User.find_by_reset_auth_token(params[:code])
      if Time.now <= user.reset_auth_token_expires_at
        @identifier = user.openid_identifiers.first || user.openid_identifiers.build
        if using_open_id?
          begin
            authenticate_with_open_id do |result, identity_url|
              if result.successful?
                @identifier.url = identity_url
                if @identifier.save
                  user.determination_reset_auth_token
                  flash[:notice] = _("%{function} completed.")%{:function => _('Resetting OpenID URL')} + _("Enter the previously set URL to log in.")
                  redirect_to [current_tenant, :platform]
                end
              else
                flash.now[:error] = _("OpenID processing aborted due to user cancellation or system errors.")
              end
            end
          rescue OpenIdAuthentication::InvalidOpenId
            flash.now[:error] = _("OpenID format invalid.")
          end
        end
      else
        flash[:error] = _("The URL for %{function} has expired.")%{:function => _('resetting OpenID URL')}
        redirect_to [current_tenant, :platform]
      end
    else
      flash[:error] = _("The URL for %{function} invalid. Try again or contact system administrator.")%{:function => _('resetting OpenID URL')}
      redirect_to [current_tenant, :platform]
    end
  end

  private
  def require_not_login
    if logged_in?
      unless current_user.unused?
        redirect_to_return_to_or_root
      else
        redirect_to new_polymorphic_url([current_tenant, :user])
      end
    end
  end

  def login_with_open_id
    session[:return_to] = params[:return_to] if !params[:return_to].blank? and params[:open_id_complete].blank?
    begin
      authenticate_with_open_id(params[:openid_url], :method => 'post',
                                :required => GlobalInitialSetting["ax_fetchrequest"].values.flatten) do |result, identity_url, registration|
        if result.successful?
          logger.info("[Login successful with OpenId] \"OpenId\" => #{identity_url}")
          remove_current_page_from_cookie
          unless identifier = OpenidIdentifier.find_by_url(identity_url)
            create_user_from(identity_url, registration)
          else
            return_to = session[:return_to]

            request_token = session[:request_token]
            reset_session
            session[:request_token] = request_token
            # TODO: 該当するOpenIDのユーザを探すときに、テナント内のユーザであるというチェックが必要か？
            self.current_user = identifier.user_with_unused
            redirect_to_return_to_or_root(return_to)
          end
        else
          logger.info("[Login failed with OpenId] \"OpenId\" => #{identity_url}")
          set_error_message_form_result_and_redirect(result)
        end
      end
    rescue OpenIdAuthentication::InvalidOpenId
      logger.info("[Login failed with OpenId] \"OpenId is invalid\"")
      flash[:error] = _("OpenID format invalid.")
      redirect_to [:platform]
    end
  end

  def create_user_from(identity_url, registration)
    if tenant = Tenant.find_by_op_endpoint(params["openid.op_endpoint"])
      user = User.create_with_identity_url(identity_url, create_user_params(registration, tenant))
      if user.valid?
        reset_session
        self.current_user = user

        redirect_to new_polymorphic_url([tenant, :user])
      else
        set_error_message_from_user_and_redirect(user)
      end
    else
      set_error_message_not_create_new_user_and_redirect
    end
  end

  def redirect_to_return_to_or_root(return_to = params[:return_to])
    return_to = return_to ? URI.encode(return_to) : nil
    redirect_to (return_to and !return_to.empty?) ? return_to : root_url
  end

  def create_user_params(fetched, tenant)
    returning({}) do |res|
      GlobalInitialSetting["ax_fetchrequest"].each do |k, vs|
        fetched.each{|fk, (fv,_)| res[k] = fv if !fv.blank? && vs == fk }
      end
      res[:tenant] = tenant
    end
  end

  def set_error_message_form_result_and_redirect(result)
    error_messages = {
      :missing      => _("OpenID server not found. Please provide a correct OpenID URL."),
      :canceled     => _("Operation cancelled. Please confirm to authenticate with the server."),
      :failed       => _("Authentication failed."),
      :setup_needed => _("Internal error(s) occured. Contact administrator.")
    }
    set_error_message_and_redirect error_messages[result.instance_variable_get(:@code)]
  end

  def set_error_message_from_user_and_redirect(user)
    logger.error("[FIXED OP ERROR] User cannot create because #{user.errors.full_messages}")
    logger.error("[DETAIL USER INFO] #{user.attributes.inspect}")
    set_error_message_and_redirect _("Failed to register user. Contact administrator %{contact_addr}.<br/>%{msg}")%{:contact_addr => Admin::Setting.contact_addr(current_tenant), :msg => user.errors.full_messages}
  end

  def set_error_message_not_create_new_user_and_redirect
    set_error_message_and_redirect _("OpenID had not been registered. Log in, register the OpenID URL in the administration screen then log in again.")
  end

  def set_error_message_and_redirect(message)
    flash[:error] = message
    redirect_to :platform
  end

  def login_with_password
    logout_killing_session!([:request_token])
    if params[:login]
      User.auth(params[:login][:key], params[:login][:password], params[:login][:keyphrase]) do |result, user|
        if result
          self.current_user = user
          logger.info(current_user.to_s_log('[Login successful with password]'))
          remove_current_page_from_cookie
          handle_remember_cookie!(params[:login_save] == 'true')
          redirect_to_return_to_or_root
        else
          if user
            if user.locked?
              reason = _("%s is locked. Please reset password.") % Admin::Setting.login_account(current_tenant)
              redirect_to_url = forgot_password_url
            elsif !user.within_time_limit_of_password?
              reason = _("Password is expired. Please reset password.")
              redirect_to_url = forgot_password_url
            end
          else
            reason = _("Log in failed.")
            redirect_to_url = (request.env['HTTP_REFERER'] ? :back : login_url)
          end
          key = params[:login] ? params[:login][:key] : ""
          logger.info("[Login failed with password] login_key[#{key}] by #{reason}")
          flash[:error] = reason
          redirect_to redirect_to_url
        end
      end
    else
      logger.info("[Login failed with password] by bad_request")
      flash[:error] = _("Log in failed.")
      redirect_to (request.env['HTTP_REFERER'] ? :back : polymorphic_url([current_tenant, :platform], :action => :login))
    end
  end

  def remove_current_page_from_cookie
    cookies.delete :target_key2current_pages
  end
end
