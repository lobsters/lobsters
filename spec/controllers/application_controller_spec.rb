require 'rails_helper'

describe ApplicationController do
  describe 'rescuing format errors' do
    controller do
      def with_respond_to
        respond_to do |format|
          format.html { render plain: 'hello world', status: :ok }
        end
      end

      def with_render
        render plain: 'hello world', status: :ok
      end
    end

    # https://github.com/rspec/rspec-rails/issues/636
    before do
      routes.draw do
        get 'with_respond_to' => 'anonymous#with_respond_to'
        get 'with_render' => 'anonymous#with_render'
      end
    end

    it 'requesting valid format from respond_to works' do
      get :with_respond_to, format: :html
      expect(response).to have_http_status(:ok)
      get :with_respond_to
      expect(response).to have_http_status(:ok)
    end

    it 'requesting valid format from render call worksworks' do
      get :with_render, format: :html
      expect(response).to have_http_status(:ok)
      get :with_render
      expect(response).to have_http_status(:ok)
    end

    it 'requesting unhandled format from respond_to fails' do
      get :with_respond_to, format: :rss
      expect(response).to have_http_status(:not_found)
    end

    xit 'requesting unhandled format from render fails' do
      get :with_render, format: :rss
      expect(response).to have_http_status(:not_found)
    end
  end
end
