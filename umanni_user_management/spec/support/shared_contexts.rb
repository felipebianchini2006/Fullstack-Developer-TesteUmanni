RSpec.shared_context 'authenticated as admin' do
  let(:current_user) { create(:user, :admin) }
  before { sign_in current_user }
end

RSpec.shared_context 'authenticated as user' do
  let(:current_user) { create(:user) }
  before { sign_in current_user }
end

RSpec.shared_context 'unauthenticated' do
  before { sign_out }
end

RSpec.shared_examples 'requires authentication' do |method, path|
  context 'when user is not authenticated' do
    it 'redirects to sign in page' do
      public_send(method, path)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end

RSpec.shared_examples 'requires admin authorization' do |method, path|
  context 'when user is not an admin' do
    include_context 'authenticated as user'

    it 'returns 403 Forbidden' do
      public_send(method, path)
      expect(response).to have_http_status(:forbidden)
    end
  end
end

RSpec.shared_examples 'a validatable model' do |attribute, invalid_value|
  it "validates presence of #{attribute}" do
    subject = build(described_class.to_s.underscore.to_sym, attribute => nil)
    expect(subject).not_to be_valid
  end

  it "invalidates #{attribute} with #{invalid_value}" do
    subject = build(described_class.to_s.underscore.to_sym, attribute => invalid_value)
    expect(subject).not_to be_valid
  end
end
