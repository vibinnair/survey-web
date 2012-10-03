class Organization
  def self.all_except(access_token, organization_id)
    access_token.get('/api/organizations').parsed.reject do |org|
      org['id'] == organization_id
    end
  end

  def self.users(client, organization_id)
    User.find_by_organization(client, organization_id)
  end
end