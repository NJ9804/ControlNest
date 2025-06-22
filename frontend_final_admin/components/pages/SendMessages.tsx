'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { MessageSquare, Send, Users } from 'lucide-react';
import { sendMessageToGroupId, getGroupHierarchy } from '@/lib/api';
import { useToast } from '@/hooks/use-toast';

interface Group {
  id: string;
  name: string;
  path: string;
  contactCount?: number;
  children?: Group[];
}

export default function SendMessages() {
  const [message, setMessage] = useState('');
  const [selectedGroup, setSelectedGroup] = useState<string>(''); // holds group name now
  const [groups, setGroups] = useState<Group[]>([]);
  const [sending, setSending] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    loadGroups();
  }, []);

  const loadGroups = async () => {
    try {
      const data = await getGroupHierarchy();
      setGroups(data);
    } catch (error) {
      console.error('Failed to load groups:', error);
    }
  };

  const flattenGroups = (groups: Group[], prefix = ''): { id: string; name: string; label: string; contactCount: number }[] => {
    const result: { id: string; name: string; label: string; contactCount: number }[] = [];
    
    groups.forEach(group => {
      const label = prefix ? `${prefix} > ${group.name}` : group.name;
      result.push({ id: group.id, name: group.name, label, contactCount: group.contactCount || 0 });
      
      if (group.children && group.children.length > 0) {
        result.push(...flattenGroups(group.children, label));
      }
    });
    
    return result;
  };

const flattenedGroups = flattenGroups(groups);
const selectedGroupInfo = flattenedGroups.find(g => g.id === selectedGroup);

const handleSendMessage = async () => {
  if (!message.trim() || !selectedGroup) return;

  setSending(true);
  try {
    // Use group id directly as required by the API
    await sendMessageToGroupId(Number(selectedGroup), message);
    toast({
      title: "Message sent!",
      description: "Your message has been sent successfully to the selected group and its subgroups.",
    });
    setMessage('');
    setSelectedGroup('');
  } catch (error) {
    toast({
      title: "Failed to send message",
      description: "There was an error sending your message. Please try again.",
      variant: "destructive",
    });
  } finally {
    setSending(false);
  }
};

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Send Messages</h1>
        <p className="text-gray-600 mt-2">
          Send messages to any group or subgroup
        </p>
      </div>

      {/* Message Composition */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <MessageSquare className="h-5 w-5" />
            <span>Compose Message</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Group Selection */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700">
              Select Target Group *
            </label>
            <Select value={selectedGroup} onValueChange={setSelectedGroup}>
              <SelectTrigger>
                <SelectValue placeholder="Choose a group to send message to" />
              </SelectTrigger>
              <SelectContent>
                {flattenedGroups.map((group) => (
                  <SelectItem key={group.id} value={group.id}>
                    <div className="flex items-center justify-between w-full">
                      <span>{group.label}</span>
                      <span className="text-xs text-gray-500 ml-2">
                        ({group.contactCount} contacts)
                      </span>
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {selectedGroupInfo && (
              <div className="flex items-center space-x-2 text-sm text-gray-600">
                <Users className="h-4 w-4" />
                <span>
                  This message will be sent to {selectedGroupInfo.contactCount} contacts
                </span>
              </div>
            )}
          </div>

          {/* Message Input */}
          <div className="space-y-2">
            <label className="text-sm font-medium text-gray-700">
              Message Content *
            </label>
            <Textarea
              placeholder="Type your message here..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={6}
              className="resize-none"
            />
            <div className="flex justify-between text-sm text-gray-500">
              <span>{message.length} characters</span>
              <span>{message.length > 160 ? 'Long message' : 'SMS length'}</span>
            </div>
          </div>

          {/* Send Button */}
          <div className="flex justify-end">
            <Button
              onClick={handleSendMessage}
              disabled={!message.trim() || !selectedGroup || sending}
              className="min-w-32"
            >
              <Send className="h-4 w-4 mr-2" />
              {sending ? 'Sending...' : 'Send Message'}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Message Preview */}
      {message.trim() && selectedGroupInfo && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Message Preview</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">
                    To: {selectedGroupInfo.label}
                  </span>
                  <span className="text-xs text-gray-500">
                    {selectedGroupInfo.contactCount} recipients
                  </span>
                </div>
                <div className="bg-white p-3 rounded border">
                  <p className="text-gray-900 whitespace-pre-wrap">{message}</p>
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-center">
                <div className="p-3 bg-blue-50 rounded-lg">
                  <p className="text-sm text-blue-600 font-medium">Message Length</p>
                  <p className="text-lg font-bold text-blue-800">{message.length}</p>
                </div>
                <div className="p-3 bg-green-50 rounded-lg">
                  <p className="text-sm text-green-600 font-medium">Recipients</p>
                  <p className="text-lg font-bold text-green-800">{selectedGroupInfo.contactCount}</p>
                </div>
                <div className="p-3 bg-purple-50 rounded-lg">
                  <p className="text-sm text-purple-600 font-medium">Message Type</p>
                  <p className="text-lg font-bold text-purple-800">
                    {message.length > 160 ? 'Long SMS' : 'SMS'}
                  </p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

