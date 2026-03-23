class NotePointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_note

  def create
    @point = @note.note_points.build(note_point_params)
    respond_to do |format|
      if @point.save
        format.html { redirect_to @note }
        format.json { render json: { id: @point.id, text: @point.text, checked: @point.checked, position: @point.position, parent_id: @point.parent_id, children: [] }, status: :created }
      else
        format.html { redirect_to @note, alert: "Could not add point." }
        format.json { render json: { errors: @point.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @point = @note.note_points.find(params[:id])
    respond_to do |format|
      if @point.update(note_point_params)
        format.html { redirect_to @note }
        format.json { render json: { id: @point.id, text: @point.text, checked: @point.checked, position: @point.position, parent_id: @point.parent_id } }
      else
        format.html { redirect_to @note, alert: "Could not update point." }
        format.json { render json: { errors: @point.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @point = @note.note_points.find(params[:id])
    @point.destroy
    respond_to do |format|
      format.html { redirect_to @note }
      format.json { head :no_content }
    end
  end

  private

  def set_note
    @note = current_user.notes.find(params[:note_id])
  end

  def note_point_params
    params.require(:note_point).permit(:text, :checked, :position, :parent_id)
  end
end
