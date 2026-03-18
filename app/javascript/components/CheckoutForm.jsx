import React, { useState, useRef } from 'react';
import UserSearch from './UserSearch';

export default function CheckoutForm({
  cartItems,
  total,
  currentUserId,
  currentUserName,
  initialParticipants,
  cartPath,
  ordersPath,
  csrfToken,
}) {
  const defaultParticipants = [{ id: currentUserId, name: currentUserName }];
  const merged = initialParticipants && initialParticipants.length > 0
    ? [
        ...defaultParticipants,
        ...initialParticipants.filter(p => p.id !== currentUserId),
      ]
    : defaultParticipants;

  const [participants, setParticipants] = useState(merged);
  const formRef = useRef(null);

  const handleAddParticipant = (user) => {
    if (participants.some(p => p.id === user.id)) return;
    setParticipants(prev => [...prev, user]);
  };

  const handleRemoveParticipant = (userId) => {
    if (userId === currentUserId) return;
    setParticipants(prev => prev.filter(p => p.id !== userId));
  };

  const excludeIds = participants.map(p => p.id);

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8 flex items-center justify-between">
          <h1 className="text-3xl font-extrabold text-gray-900">Checkout</h1>
          <a href={cartPath} className="text-sm text-indigo-600 hover:text-indigo-900">Back to Cart</a>
        </div>

        <form ref={formRef} action={ordersPath} method="post" className="space-y-6">
          <input type="hidden" name="authenticity_token" value={csrfToken} />

          {participants.map(p => (
            <input key={p.id} type="hidden" name="order[participant_ids][]" value={p.id} />
          ))}

          <div className="bg-white shadow rounded-lg overflow-hidden">
            <div className="px-6 py-4 bg-gray-50 border-b border-gray-200">
              <h2 className="text-lg font-semibold text-gray-900">Order Summary</h2>
            </div>
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Article</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Qty</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Total</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {cartItems.map((item, i) => (
                  <tr key={i}>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{item.title}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{item.price} RSD</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{item.quantity}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 text-right">{item.line_total} RSD</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="bg-gray-50">
                  <td colSpan="3" className="px-6 py-4 text-sm font-semibold text-gray-900 text-right">Total:</td>
                  <td className="px-6 py-4 text-sm font-semibold text-gray-900 text-right">{total} RSD</td>
                </tr>
              </tfoot>
            </table>
          </div>

          <div className="bg-white shadow rounded-lg">
            <div className="px-6 py-4 bg-gray-50 border-b border-gray-200 rounded-t-lg">
              <h2 className="text-lg font-semibold text-gray-900">Participants</h2>
            </div>
            <div className="px-6 py-6">
              <p className="text-sm text-gray-500 mb-4">
                Select users who will participate in this order. You can configure splitting after the order is created.
              </p>

              <div className="flex flex-wrap gap-2 mb-4">
                {participants.map(p => (
                  <span
                    key={p.id}
                    className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-50 text-indigo-700 text-sm"
                  >
                    {p.name}
                    {p.id !== currentUserId && (
                      <button
                        type="button"
                        onClick={() => handleRemoveParticipant(p.id)}
                        className="text-indigo-400 hover:text-indigo-600 cursor-pointer"
                      >
                        &times;
                      </button>
                    )}
                  </span>
                ))}
              </div>

              <UserSearch onSelect={handleAddParticipant} excludeIds={excludeIds} />
            </div>
          </div>

          <div className="flex justify-end gap-3">
            <a href={cartPath} className="py-2 px-4 rounded-md text-sm font-medium text-gray-700 border border-gray-300 hover:bg-gray-50">
              Back to Cart
            </a>
            <button type="submit" className="py-2 px-4 rounded-md text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 cursor-pointer">
              Place Order
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
