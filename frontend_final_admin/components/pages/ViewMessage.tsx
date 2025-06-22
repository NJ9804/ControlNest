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
import { getMessageHistory, deleteMessage } from '@/lib/api';
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

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <MessageSquare className="h-5 w-5 text-blue-600" />
              <div>
                <p className="text-sm text-gray-600">Total Messages</p>
                <p className="text-2xl font-bold text-gray-900">
                  {loading ? '...' : messages.length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <Users className="h-5 w-5 text-green-600" />
              {/* <div>
                <p className="text-sm text-gray-600">Total Recipients</p>
                <p className="text-2xl font-bold text-gray-900">
                  {loading ? '...' : messages.reduce((sum, msg) => sum + (msg.recipient_count || 0), 0)}
                </p>
              </div> */}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <Calendar className="h-5 w-5 text-purple-600" />
              <div>
                <p className="text-sm text-gray-600">Recent Messages</p>
                <p className="text-2xl font-bold text-gray-900">
                  {loading ? '...' : messages.filter(msg => {
                    const msgDate = new Date(msg.timestamp);
                    const weekAgo = new Date();
                    weekAgo.setDate(weekAgo.getDate() - 7);
                    return msgDate > weekAgo;
                  }).length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <History className="h-5 w-5" />
            <span>Message History</span>
          </CardTitle>
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
            <div className="flex items-center justify-center p-8">
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
            <div className="space-y-4 max-h-96 overflow-y-auto">
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
                      <div className="bg-white p-3 rounded border">
                        <p className="text-gray-900 whitespace-pre-wrap">{message.content}</p>
                      </div>
                      <div className="flex items-center space-x-4 text-xs text-gray-500">
                        <span>Length: {message.content.length} chars</span>
                        <span>Type: {message.content.length > 160 ? 'Long SMS' : 'SMS'}</span>
                      </div>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleDeleteMessage(message.id)}
                      disabled={deleting === message.id}
                      className="ml-4 text-red-600 hover:text-red-700 hover:bg-red-50"
                    >
                      {deleting === message.id ? (
                        <RefreshCw className="h-4 w-4 animate-spin" />
                      ) : (
                        <Trash2 className="h-4 w-4" />
                      )}
                    </Button>
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
                  This action cannot be undone. Messages that have already been sent
                  to recipients will not be recalled.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
        
