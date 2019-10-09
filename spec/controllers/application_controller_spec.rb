require 'rails_helper'

describe ApplicationController do
  describe 'rescuing for unkown format errors' do
    controller do
      def index
        respond_to do |format|
          format.html { render plain: 'hello world', status: :ok }
        end
      end
    end

    before do
      get :index, format: request_format
    end

    context 'requesting with handeled format' do
      let(:request_format) { :html }

      it 'responses with the expected http status code' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'requesting with unhandeled format' do
      let(:request_format) { :flv }

      it 'responses with a error inicating http status code' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
