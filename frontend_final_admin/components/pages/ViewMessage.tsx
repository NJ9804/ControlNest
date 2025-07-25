'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  History,
  Search,
  Trash2,
  RefreshCw,
  MessageSquare,
  Calendar,
  Users,
  AlertTriangle
} from 'lucide-react';
import { getMessageHistory, deleteMessage, updateMessage } from '@/lib/api';
import { useToast } from '@/hooks/use-toast';

interface Message {
  id: number;
  group: string;
  content: string;
  priority: string;
  expiry: string;
  timestamp: string;
}

export default function ViewMessages() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [deleting, setDeleting] = useState<number | null>(null);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editContent, setEditContent] = useState('');
  const [editPriority, setEditPriority] = useState('');
  const [editExpiry, setEditExpiry] = useState('');
  const { toast } = useToast();

  useEffect(() => {
    loadMessages();
  }, []);

  const loadMessages = async () => {
    setLoading(true);
    try {
      const data = await getMessageHistory();
      console.log('Loaded messages:', data);
      setMessages(data);
    } catch (error) {
      console.error('Failed to load messages:', error);
      toast({
        title: "Failed to load messages",
        description: "There was an error loading the message history.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteMessage = async (messageId: number) => {
    if (!Number.isInteger(messageId) || messageId <= 0) {
      toast({
        title: "Invalid message ID",
        description: `The message ID "${messageId}" is not valid.`,
        variant: "destructive",
      });
      return;
    }

    setDeleting(messageId);
    try {
      await deleteMessage(messageId);
      toast({
        title: "Message deleted",
        description: `Message ID ${messageId} has been successfully deleted.`,
      });
      // Remove the deleted message from state
      setMessages((prev) => prev.filter((msg) => msg.id !== messageId));
    } catch (error) {
      toast({
        title: "Delete failed",
        description: (error as Error).message,
        variant: "destructive",
      });
    } finally {
      setDeleting(null);
    }
  };

  const handleEditClick = (msg: Message) => {
    setEditingId(msg.id);
    setEditContent(msg.content);
    setEditPriority(msg.priority);
    setEditExpiry(msg.expiry);
  };

  const handleEditCancel = () => {
    setEditingId(null);
    setEditContent('');
    setEditPriority('');
    setEditExpiry('');
  };

  const handleEditSave = async (msg: Message) => {
    try {
      await updateMessage(msg.id, {
        content: editContent,
        priority: editPriority,
        expiry: editExpiry,
      });
      toast({
        title: 'Message updated',
        description: `Message ID ${msg.id} has been updated.`,
      });
      setMessages((prev) =>
        prev.map((m) =>
          m.id === msg.id
            ? { ...m, content: editContent, priority: editPriority, expiry: editExpiry }
            : m
        )
      );
      handleEditCancel();
    } catch (error) {
      toast({
        title: 'Update failed',
        description: (error as Error).message,
        variant: 'destructive',
      });
    }
  };

  const formatDate = (timestamp: string) => {
    try {
      return new Date(timestamp).toLocaleString();
    } catch {
      return timestamp;
    }
  };

  const filteredMessages = messages.filter(message =>
    message.content.toLowerCase().includes(searchTerm.toLowerCase()) ||
    message.group.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Message History</h1>
          <p className="text-gray-600 mt-2">View and manage all sent messages</p>
        </div>
        <Button onClick={loadMessages} disabled={loading} variant="outline">
          <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>


      <Card>
        <CardHeader>
            <div className="flex items-center justify-between w-full">
            <CardTitle className="flex items-center space-x-2">
              <History className="h-10 w-10" />
              <span>Message History</span>
            </CardTitle>
            <div className="text-right">
              <p className="text-sm text-gray-600">Total Messages</p>
              <p className="text-2xl font-bold text-gray-900">
              {loading ? '...' : messages.length}
              </p>
            </div>
            </div>
          <div className="flex items-center space-x-2">
            <Search className="h-4 w-4 text-gray-400" />
            <Input
              placeholder="Search messages or groups..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="max-w-sm"
            />
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center p-10">
              <RefreshCw className="h-6 w-6 animate-spin text-gray-400" />
              <span className="ml-2 text-gray-600">Loading messages...</span>
            </div>
          ) : filteredMessages.length === 0 ? (
            <div className="text-center p-8 text-gray-500">
              <MessageSquare className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p className="text-lg font-medium mb-2">
                {searchTerm ? 'No messages found' : 'No messages yet'}
              </p>
              <p className="text-sm">
                {searchTerm
                  ? 'Try adjusting your search terms'
                  : 'Messages will appear here once you start sending them'}
              </p>
            </div>
          ) : (
            <div className="space-y-4 max-h-[60vh] overflow-y-auto">
              {filteredMessages.map((message) => (
                <div
                  key={message.id}
                  className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1 space-y-2">
                      <div className="flex items-center space-x-4 text-sm text-gray-600">
                        <div className="flex items-center space-x-1">
                          <Users className="h-4 w-4" />
                          <span className="font-medium">{message.group}</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <Calendar className="h-4 w-4" />
                          <span>{message.timestamp}</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <AlertTriangle className="h-4 w-4" />
                          <span className="capitalize">{message.priority}</span>
                        </div>
                        <div className="flex items-center space-x-1">
                          <History className="h-4 w-4" />
                          <span>Expires: {message.expiry}</span>
                        </div>
                      </div>
                      {editingId === message.id ? (
                        <div className="bg-white p-3 rounded border space-y-2">
                          <textarea
                            className="w-full border rounded p-2"
                            value={editContent}
                            onChange={(e) => setEditContent(e.target.value)}
                            rows={3}
                          />
                          <div className="flex space-x-2">
                            <select
                              className="border rounded p-1 text-xs"
                              value={editPriority}
                              onChange={(e) => setEditPriority(e.target.value)}
                            >
                              <option value="low">Low</option>
                              <option value="medium">Medium</option>
                              <option value="high">High</option>
                            </select>
                            <input
                              type="date"
                              className="border rounded p-1 text-xs"
                              placeholder="Expiry (YYYY-MM-DD)"
                              value={editExpiry.slice(0, 10)}
                              onChange={(e) => setEditExpiry(e.target.value)}
                            />
                          </div>
                          <div className="flex space-x-2 mt-2">
                            <Button size="sm" onClick={() => handleEditSave(message)} disabled={deleting === message.id}>
                              Save
                            </Button>
                            <Button size="sm" variant="outline" onClick={handleEditCancel}>
                              Cancel
                            </Button>
                          </div>
                        </div>
                      ) : (
                        <div className="bg-white p-3 rounded border">
                          <p className="text-gray-900 whitespace-pre-wrap">{message.content}</p>
                        </div>
                      )}
                      <div className="flex items-center space-x-4 text-xs text-gray-500">
                        <span>Length: {message.content.length} chars</span>
                        <span>Type: {message.content.length > 160 ? 'Long SMS' : 'SMS'}</span>
                      </div>
                    </div>
                    <div className="flex flex-col items-end space-y-2 ml-4">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleDeleteMessage(message.id)}
                        disabled={deleting === message.id}
                        className="text-red-600 hover:text-red-700 hover:bg-red-50"
                      >
                        {deleting === message.id ? (
                          <RefreshCw className="h-4 w-4 animate-spin" />
                        ) : (
                          <Trash2 className="h-4 w-4" />
                        )}
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEditClick(message)}
                        disabled={editingId !== null && editingId !== message.id}
                        className="text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                      >
                        Edit
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {messages.length > 0 && (
        <Card className="border-orange-200 bg-orange-50">
          <CardContent className="p-4">
            <div className="flex items-start space-x-3">
              <AlertTriangle className="h-5 w-5 text-orange-600 mt-0.5" />
              <div className="text-sm text-orange-800">
                <p className="font-medium mb-1">Important Notice</p>
                <p>
                  Deleting messages will permanently remove them from the system.
                  This action cannot be undone.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

