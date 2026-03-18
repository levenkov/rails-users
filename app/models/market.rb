class Market < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  has_many :articles, dependent: :destroy
  has_one_attached :logo
  has_many_attached :photos

  validates :name, presence: true
end
