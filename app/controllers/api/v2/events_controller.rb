module Api::V2
  class EventsController < ApplicationController
#  skip_before_filter :authenticate_user_from_token!
#  skip_before_filter :authenticate_me!
#  protect_from_forgery :except => [:create]


    def create
      respond_to do |format|
        format.xml {
          handle_xml()
        }
      end
    end

    def handle_xml
      document = Nokogiri::XML(request.body.read)
      notification = EventNotification.new(document)
      if fail_authentication(notification.user_token)
        render :status => 401, :nothing => true
      else
        if notification.save
          render :status => 202, :nothing => true
        else
          render :status => 422, :xml => notification.errors
        end
      end
    end

    protected

    def fail_authentication(user_token)
      user = user_token && User.find_by_authentication_token(user_token.to_s)

      if user
        sign_in user, store: false
        return false
      end
      true
    end
  end
end
