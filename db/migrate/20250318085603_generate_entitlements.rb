class GenerateEntitlements < ActiveRecord::Migration[7.2]
  def change
    Chat.all.each do |chat|
      owner_chat_users = chat.chat_users.where(role: :chat_admin)

      owner_chat_users.each do |owner|
        owner.generate_entitlement

        owner_entitlement = Entitlement.find_or_create_by(object: chat, flag: 'permission', data: 'owner')
        owner.user.entitlements << owner_entitlement if owner.user.entitlements.exclude?(owner_entitlement)
      end

      other_chat_users = chat.chat_users.where.not(role: :chat_admin)

      other_chat_users.each do |chat_user|
        chat_user.generate_entitlement
      end
    end

    Theme.all.each do |theme|
      entitlement = Entitlement.find_or_create_by(object: theme)
      theme.user.entitlements << entitlement if theme.user.entitlements.exclude?(entitlement)
    end

    User.all.each do |user|
      entitlement = Entitlement.find_or_create_by(flag: 'pseudonym', data: user.username)
      user.entitlements << entitlement if user.entitlements.exclude?(entitlement)
    end
  end
end
