require 'spec_helper'

describe ConversationsController do
  let!(:account) { create(:account) }
  let!(:next_conversation) { create(:conversation_with_messages, account: account) }
  let!(:conversation) { create(:conversation_with_messages, account: account) }
  let!(:archived_conversation) { create(:conversation_with_messages, account: account, archived: true) }
  let!(:user) { create(:user_with_account, account: account) }

  before { sign_in(user) }

  describe '#archived' do
    it 'shows all archived conversations' do
      get :archived,
        {
          account_id: account.slug
        }

      expect(response).to be_successful
      expect(assigns(:conversations)).to eq([archived_conversation])
      expect(assigns(:conversation)).to eq(archived_conversation)
    end
  end

  describe '#show' do
    it 'shows a conversation' do
      get :show,
        {
          account_id: account.slug,
          id: conversation.number
        }

      expect(assigns(:conversation)).to eq(conversation)
      expect(assigns(:next_conversation)).to eq(next_conversation)
    end

    it 'shows an archived conversation' do
      get :show,
        {
          account_id: account.slug,
          id: archived_conversation.number
        }

      expect(response).to be_successful
      expect(assigns(:conversation)).to eq(archived_conversation)
      expect(assigns(:next_conversation)).to be_nil
    end
  end

  describe '#update' do
    it 'archives a conversation' do
      post :update,
        {
          account_id: account.slug,
          id: conversation.number,
          conversation: {
            archive: true
          }
        }

      conversation.reload

      expect(conversation).to be_archived
      expect(response).to redirect_to inbox_account_conversations_path(account)
      expect(flash[:notice]).to eq("The conversation has been archived.")
    end

    it 'unarchives a conversation' do
      conversation.archive!

      post :update,
        {
          account_id: account.slug,
          id: conversation.number,
          conversation: {
            unarchive: true
          }
        }

      conversation.reload

      expect(conversation).not_to be_archived
      expect(response).to redirect_to inbox_account_conversations_path(account)
      expect(flash[:notice]).to eq("The conversation has been moved to the inbox.")
    end

    it 'moves a conversation to the bottom of the queue' do
      post :update,
        {
          account_id: account.slug,
          id: conversation.number,
          conversation: {
            respond_later: true
          }
        }

      conversation.reload

      expect(conversation.respond_laters).not_to be_empty
    end
  end
end
