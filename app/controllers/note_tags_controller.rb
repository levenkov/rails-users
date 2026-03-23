class NoteTagsController < ApplicationController
  before_action :authenticate_user!

  def index
    @tags = current_user.note_tags.order(:name)
    respond_to do |format|
      format.html
      format.json { render json: @tags.map { |t| { id: t.id, name: t.name } } }
    end
  end

  def create
    @tag = current_user.note_tags.build(note_tag_params)
    respond_to do |format|
      if @tag.save
        format.html { redirect_to note_tags_path }
        format.json { render json: { id: @tag.id, name: @tag.name }, status: :created }
      else
        format.html { redirect_to note_tags_path, alert: @tag.errors.full_messages.join(", ") }
        format.json { render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @tag = current_user.note_tags.find(params[:id])
    @tag.destroy
    respond_to do |format|
      format.html { redirect_to note_tags_path }
      format.json { head :no_content }
    end
  end

  private

  def note_tag_params
    params.require(:note_tag).permit(:name)
  end
end
